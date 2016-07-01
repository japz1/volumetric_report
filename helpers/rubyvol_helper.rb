# Decompress NIFTI .gz files
def decompress(filename)
  basename = File.basename(filename, '.nii.gz')
  dirname = File.dirname(filename)
  `gzip -d #{filename}`
  filename_d = dirname+'/'+basename+'.nii'
  return filename_d
end

def get_niftifile(path)
  niftifile = ""
  Find.find(path) do |path|
    niftifile = path if path.to_s.end_with?(".nii")
  end
  return niftifile
end

def get_dicomfile(path)
  dicomfile = ""
  Find.find(path) do |path|
    dicomfile = path if path.to_s.end_with?(".dcm")
  end
  return dicomfile 
end

def read_nifti(nii_file)
  NIFTI::NObject.new(nii_file, :narray => true).image.to_i
end

def get_2d_slice(ni3d, dim, slice_num,orientation)
  puts "Extracting 2D slice number #{slice_num} on dimension #{dim} for volume."
  #case orientation
    #when 'axial'
    if dim == 1
      ni3d[slice_num,true,true]
    elsif dim == 2
      ni3d[true,slice_num,true]
    elsif dim == 3
      ni3d[true,true,slice_num]
    else
      raise "No valid dimension specified for slice extraction"
    end
    #when 'sagital'
    #end
end

def normalise(x,xmin,xmax,ymin,ymax)
    xrange = xmax-xmin
    yrange = ymax-ymin
    ymin + (x-xmin) * (yrange.to_f / xrange)
end

def png_from_nifti_img(ni2d) # Create PNG object from NIFTI image NArray 2D Image
  puts "Creating PNG image for 2D nifti slice"
  # Create PNG
  png = ChunkyPNG::Image.new(ni2d.shape[0], ni2d.shape[1], ChunkyPNG::Color::TRANSPARENT)

  # Fill PNG with values from slice NArray
  png.height.times do |y|
    png.row(y).each_with_index do |pixel, x|
      val = ni2d[x,y]
      valnorm = normalise(val, ni2d.min, ni2d.max, 0, 255).to_i
      png[x,y] = ChunkyPNG::Color.rgb(valnorm, valnorm, valnorm)
    end
  end
  # return PNG
  return png
end

def generate_label_map_png(base_slice, label_slice, label, label_color) # Applies a label map over a base image
  base_png = png_from_nifti_img(base_slice)
  # Fill PNG with values from slice NArray
  base_png.height.times do |y|
    base_png.row(y).each_with_index do |pixel, x|
      val = label_slice[x,y]

      if label.class != String 
        base_png[x,y] = label_color["general"] if val == label
      else
        if val == 10 or val == 49
          base_png[x,y] = label_color["talamo"]
        elsif val == 11 or val == 50
          base_png[x,y] = label_color["caudate"]
        elsif val == 12 or val == 51
          base_png[x,y] = label_color["putamen"]
        elsif val == 13 or val == 52
          base_png[x,y] = label_color["padillum"]
        elsif val == 17 or val ==53
          base_png[x,y] = label_color["hippocampus"]
        elsif val == 18 or val == 54
          base_png[x,y] = label_color["amygdala"]
        elsif val == 26 or val == 58
          base_png[x,y] = label_color["accumbens"]
        end
      end
    end
  end

  # return PNG
  return base_png
end

def generate_png_slice(nii_file, dim, slice)
  nifti = NIFTI::NObject.new(nii_file, :narray => true).image.to_i
  nifti_slice = get_2d_slice(nifti, dim, sel_slice)
  png = png_from_nifti_img(nifti_slice)
  return png
end

def coord_map(coord)
  lh = {} #lhipp_label
  rh = {} #rhipp_label
  lac = {} #laccu_label
  rac = {} #raccu_label
  lam = {} #lamyg_label
  ram = {} #ramyg_label
  lca = {} #lcaud_label
  rca = {} #rcaud_label 
  lpa = {} #lpall_label
  rpa = {} #rpall_label 
  lpu = {} #lputa_label
  rpu = {} #rputa_label
  lth = {} #lthal_label
  rth = {} #rthal_label
  i = 0


  axis = ["x", "y", "z"]

  coord_struc = [lh, rh, lac, rac, lam, ram, lca, rca, lpa, rpa, lpu, rpu, lth, rth]

  coord_struc.each do |a|
    a[axis[0]] = coord[3*i].to_i.round
    a[axis[1]] = coord[3*i+1].to_i.round
    a[axis[2]] = coord[3*i+2].to_i.round
    i +=1
  end

  return [lh,rh,lac,rac,lam,ram,lca,rca,lpa,rpa,lpu,rpu,lth,rth]
end

def get_volumes(label, first_images)
  # Get volumes
  vol_mm = FSL::Stats.new(first_images[:firstseg], false, {low_threshold: label - 0.5, up_threshold: label + 0.5, voxels_nonzero: true}).command.split[1]
  vol = sprintf('%.2f', (vol_mm.to_f))
  return vol
end

def get_slices(cog, anatomico_3d_nifti, structure_3d_nifti, orientation, outputdir, label, struct, label_color)
  (1..3).each do |sel_dim|
    # Left Hippocampus
    sel_slice = cog.values[sel_dim-1]
    anatomico_2d_slice = get_2d_slice(anatomico_3d_nifti, sel_dim, sel_slice, orientation)
    structure_2d_slice = get_2d_slice(structure_3d_nifti, sel_dim, sel_slice, orientation)
    # Overlay hippocampus label map and flip for display
    labeled_png = generate_label_map_png(anatomico_2d_slice, structure_2d_slice, label, label_color).flip_horizontally!
    # Save Labeled PNG
    labeled_png.save("#{outputdir}/#{struct}_#{sel_dim}_labeled.png")
  end
end

def create_pdf(patfname,patlname,pat_id,study_date, pat_age, outputdir, main_structure, l_label,r_label,l_volume,r_volume,index_A,structure,all_volumes,all_index_A)
  structure_names={"lh_cog" => "hippocampus", "rh_cog" => "hippocampus", "lac_cog" => "accumbens_nucleus", "rac_cog" => "accumbens_nucleus", "lam_cog" => "amygdala", "ram_cog" => "amygdala", "lca_cog" => "caudate_nucleus", "rca_cog" => "caudate_nucleus", "lpa_cog" => "pallidum", "rpa_cog" => "pallidum", "lpu_cog" => "putamen", "rpu_cog" => "putamen", "lth_cog" => "thalamus", "rth_cog" => "thalamus"}
  header = File.absolute_path("images/header.png")
  pdfname = "#{outputdir}/volumetric_report_#{pat_id}_#{structure_names[structure]}.pdf"

  Prawn::Document.generate(pdfname) do |pdf|


    #Header image Path 
    pdf.image "#{header}", :width => 630, :height => 70, :at => [-40, 760] #:position => :center

    all_volumes.each  { |k,v| all_volumes[k] = (v.to_f/1000).round(2)}
    l_volume = (l_volume.to_f/1000).round(2)
    r_volume = (r_volume.to_f/1000).round(2)

    # Title
    pdf.move_down 35

    pdf.text "Patient name: #{patfname} #{patlname}    Id: #{pat_id}    Age: #{pat_age}" , size: 10, style: :bold, :align => :center
    pdf.move_down 20

    # SubTitle RH
    if structure_names[structure] != "amygdala"
      pdf.text "#{structure_names[structure]} Right" , size: 13, style: :bold, :align => :center
    else 
      pdf.text "#{structure_names[structure]} Rignt" , size: 13, style: :bold, :align => :center
    end
    pdf.move_down 5

    # Images RH  
    pdf.image "#{outputdir}/#{r_label}_3_labeled.png", :width => 200, :height => 200, :position => 95
    pdf.move_up 200
    pdf.image "#{outputdir}/#{r_label}_2_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.image "#{outputdir}/#{r_label}_1_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.move_down 20

    # SubTitle LH
    if structure_names[structure] != "amygdala"
      pdf.text "#{structure_names[structure]} left" , size: 13, style: :bold, :align => :center
    else       
      pdf.text "#{structure_names[structure]} left" , size: 13, style: :bold, :align => :center
    end
    pdf.move_down 5

    # Images LH
    pdf.image "#{outputdir}/#{l_label}_3_labeled.png", :width => 200, :height => 200, :position => 95
    pdf.move_up 200
    pdf.image "#{outputdir}/#{l_label}_2_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.image "#{outputdir}/#{l_label}_1_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.move_down 40

    #Volumes Table New

    if structure_names[structure] != "amygdala"
      volumesTable = [["Volume #{structure_names[structure]} right:  #{r_volume} cm3", "Volumen #{structure_names[structure]} left:  #{l_volume} cm3"]]
    else 
      volumesTable = [["Volume #{structure_names[structure]} right:  #{r_volume} cm3", "Volumen #{structure_names[structure]} left:  #{l_volume} cm3"]]
    end
    pdf.table volumesTable, column_widths: [270,270], cell_style:  {padding: 12, height: 40}
    pdf.move_down 15
    pdf.text "Asymmetry index: #{sprintf("%.4f",index_A)}" , size: 12, :align => :center

    if structure_names[structure] == main_structure
      pdf.start_new_page
      pdf.image "#{header}", :width => 630, :height => 70, :at => [-40, 760]
      pdf.move_down 35
      pdf.text "Patient name: #{patfname} #{patlname}    Id: #{patid}    Age: #{pat_age}" , size: 10, style: :bold, :align => :center
      pdf.move_down 20

      pdf.text "Subcortical structures" , size: 13, style: :bold, :align => :center
      pdf.move_down 5

      pdf.image "#{outputdir}/all_labels_3_labeled.png", :width => 300, :height => 300, :position => 30
      pdf.move_up 300
      pdf.image "#{outputdir}/all_labels_2_labeled.png", :width => 225, :height => 150, :position => 285
      pdf.image "#{outputdir}/all_labels_1_labeled.png", :width => 225, :height => 150, :position => 285
      pdf.move_down 20

      all_volumesTable = [["<b>Structure</b> ", "<b>Total volume</b>", "<b>Right volume</b>", "<b>Left volume</b>", "<b>Indice de Asimetría</b>"],
                          ["Hipocampo", "#{(all_volumes[:lhipp_vol]+all_volumes[:rhipp_vol]).round(2)}","#{all_volumes[:rhipp_vol]}","#{all_volumes[:lhipp_vol]}", sprintf("%.4f",all_index_A[0]) ],
                          ["Amígdala", "#{(all_volumes[:lamyg_vol] + all_volumes[:ramyg_vol]).round(2)}","#{all_volumes[:ramyg_vol]}","#{all_volumes[:lamyg_vol]}", sprintf("%.4f",all_index_A[2]) ],
                          ["Núcleo Accumbens", "#{(all_volumes[:laccu_vol]+all_volumes[:raccu_vol]).round(2)}","#{all_volumes[:raccu_vol]}","#{all_volumes[:laccu_vol]}", sprintf("%.4f",all_index_A[1]) ],
                          ["Núcleo Caudado", "#{(all_volumes[:lcaud_vol]+all_volumes[:rcaud_vol]).round(2)}","#{all_volumes[:rcaud_vol]}","#{all_volumes[:lcaud_vol]}", sprintf("%.4f",all_index_A[3]) ],
                          ["Globo Pálido", "#{(all_volumes[:lpall_vol]+all_volumes[:rpall_vol]).round(2)}","#{all_volumes[:rpall_vol]}","#{all_volumes[:lpall_vol]}", sprintf("%.4f",all_index_A[4]) ],
                          ["Putamen", "#{(all_volumes[:lputa_vol]+all_volumes[:rputa_vol]).round(2)}","#{all_volumes[:rputa_vol]}","#{all_volumes[:lputa_vol]}", sprintf("%.4f",all_index_A[5]) ],
                          ["Tálamo", "#{(all_volumes[:ltha_vol]+all_volumes[:rtha_vol]).round(2)}","#{all_volumes[:rtha_vol]}","#{all_volumes[:ltha_vol]}", sprintf("%.4f",all_index_A[6]) ]
                          ]
      pdf.table all_volumesTable, :position => :center, :cell_style => {align: :center, :inline_format => true, :size => 12} 

      pdf.move_down 60
      pdf.text "* Asymmetry was measured as the right-minus-left volume difference as a fraction of the mean volume" , size: 8, :align => :center


      ############new#############
      pdf.start_new_page
      pdf.image "#{header}", :width => 630, :height => 70, :at => [-40, 760]
      pdf.move_down 35
      pdf.text "Patient name: #{patfname} #{patlname}    Id: #{pat_id}    Age: #{pat_age}" , size: 10, style: :bold, :align => :center   
      pdf.move_down 5
      pdf.text "Comparision with Control Group", size: 15, style: :bold, :align => :center
      pdf.move_down 10
      pdf.image "#{outputdir}/Left-Hippocampus_Right-Hippocampus.png", :scale => 0.43, :at => [0,650]
      pdf.image "#{outputdir}/Left-Amygdala_Right-Amygdala.png", :scale => 0.43, :at => [280,650]
      pdf.image "#{outputdir}/Left-Caudate_Right-Caudate.png", :scale => 0.43, :at => [0,430]
      pdf.image "#{outputdir}/Left-Thalamus_Right-Thalamus.png", :scale => 0.43, :at => [280,430]
      pdf.image "#{outputdir}/Left-Putamen_Right-Putamen.png", :scale => 0.43, :at => [0,210]
      pdf.image "#{outputdir}/Left-Accumbens_Right-Accumbens.png", :scale => 0.43, :at => [280,210]


      pdf.start_new_page
      pdf.image "#{header}", :width => 630, :height => 70, :at => [-40, 760]
      pdf.move_down 35
      pdf.text "Patient name: #{patfname} #{patlname}    Id: #{pat_id}    Age: #{pat_age}" , size: 10, style: :bold, :align => :center
      pdf.move_down 5
      pdf.text "Comparision with Control Group", size: 15, style: :bold, :align => :center
      pdf.move_down 10
      pdf.image "#{outputdir}/Left-Pallidum_Right-Pallidum.png", :scale => 0.43, :position => :center
      pdf.image "#{outputdir}/Grey-Matter_P-Cortex-GM.png", :scale => 0.43, :position => :center
      pdf.image "#{outputdir}/v-brain_.png", :scale => 0.43, :position => :center
    end
  end
end 
