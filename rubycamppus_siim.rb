#!/usr/bin/env ruby

# Modules required:
require 'rubygems'
require 'dcm2nii-ruby'
require 'fsl-ruby'
require 'narray'
require 'nifti'
require 'chunky_png'
require 'optparse'
require 'prawn'
require 'prawn/table'
require 'dicom'
include DICOM 
require 'fileutils'
require 'byebug'
require_relative 'get_csv.rb'

siena_dir = Dir.pwd

options = {}
option_parser = OptionParser.new do |opts|

  opts.on("-f DICOMDIR", "The DICOM directory") do |dicomdir|
    options[:dicomdir] = dicomdir
  end

  opts.on("-o OUTPUTDIR", "The output directory") do |outputdir|
    options[:outputdir] = outputdir
  end

  opts.on("-d ORIENTATION", "The slices orientation, e.g. sagital, coronal or axial") do |orientation|
    options[:orientation] = orientation
  end

  opts.on("-s STRUCTURE", "Select main structure, e.g. Hippocampus, Accumbens, Amygdala, Caudate, Pallidum, Putamen, Thalamus") do |structure|
    options[:main_structure] = structure
  end

  # opts.on("-s", "--studyInfo patfName,patlName,patId,studyDate, accessionNo", Array, "The study information for the report") do |study|
  #     options[:study] = study
  # end

end

option_parser.parse!

if options[:main_structure] == nil
  puts "Escribe en que estructura te gustaría que saliera el reporte de todo los volumenes subcorticáles y luego oprime enter "
  puts "e.g. Hipocampo, Núcleo Accumbens, Amígdala, Núcleo Caudado, Globo Pálido, Putamen, Tálamo"
  STDOUT.flush  
  options[:main_structure] = gets.chomp
end

dicomdir=options[:dicomdir]

if options[:outputdir] == nil
  options[:outputdir] = 'output_first'
end

#outputdir = options[:outputdir]

Dir.chdir "#{dicomdir}"
image = Dir.glob "*.dcm"
dcm = DObject.read("#{image[0]}")
studyInfo = dcm.value("0008,1030")
patName = dcm.value("0010,0010")
patId = dcm.value("0010,0020")
studyDate = dcm.value("0008,0020")
accessionNo = dcm.value("0008,0050")
patient_age = dcm.value("0010,1010")[0..2].to_i

patfName = patName[(patName =~ /\^/)+1, patName.length]
patlName = patName[0,patName =~ /\^/]

LHipp_label = 17
RHipp_label = 53
LAccu_label = 26
RAccu_label = 58
LAmyg_label = 18
RAmyg_label = 54
LCaud_label = 11
RCaud_label = 50
LPall_label = 13
RPall_label = 52
LPuta_label = 12
RPuta_label = 51
LThal_label = 10
RThal_label = 49

struct_label = {lhipp_label: 17, rhipp_label: 53, laccu_label: 26, raccu_label: 58, lamyg_label: 18, ramyg_label: 54, lcaud_label: 11, rcaud_label: 50, lpall_label: 13, rpall_label: 52, lputa_label: 12, rputa_label: 51, lthal_label: 10, rthal_label: 49 }
volumes = {lhipp_vol: -1, rhipp_vol: -1, laccu_vol: -1, raccu_vol: -1, lamyg_vol: -1, ramyg_vol: -1, lcaud_vol: -1, rcaud_vol: -1, lpall_vol: -1, rpall_vol: -1, lputa_vol: -1, rputa_vol: -1, ltha_vol: -1, rtha_vol: -1}


LabelColor = ChunkyPNG::Color.rgb(255,0,0)
LabelColorTalamo = ChunkyPNG::Color.rgb(0,118,14)
LabelColorCaudate = ChunkyPNG::Color.rgb(122,186,220)
LabelColorPutamen = ChunkyPNG::Color.rgb(236,13,176)
LabelColorPadillum = ChunkyPNG::Color.rgb(12,48,255)
LabelColorHippocampus = ChunkyPNG::Color.rgb(220,216,20)
LabelColorAmygdala = ChunkyPNG::Color.rgb(103,255,255)
LabelColorAccumbens = ChunkyPNG::Color.rgb(255,165,0)


# Decompress NIFTI .gz files
def decompress(filename)
  basename = File.basename(filename, '.nii.gz')
  dirname = File.dirname(filename)
  `gzip -d #{filename}`
  filename_d = dirname+'/'+basename+'.nii'
  return filename_d
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

def generate_label_map_png(base_slice, label_slice, label) # Applies a label map over a base image
  base_png = png_from_nifti_img(base_slice)
  # Fill PNG with values from slice NArray
  base_png.height.times do |y|
    base_png.row(y).each_with_index do |pixel, x|
      val = label_slice[x,y]

      if label.class != String 
        base_png[x,y] = LabelColor if val == label
      else
        if val == 10 or val == 49
          base_png[x,y] = LabelColorTalamo
        elsif val == 11 or val == 50
          base_png[x,y] = LabelColorCaudate
        elsif val == 12 or val == 51
          base_png[x,y] = LabelColorPutamen
        elsif val == 13 or val == 52
          base_png[x,y] = LabelColorPadillum
        elsif val == 17 or val ==53
          base_png[x,y] = LabelColorHippocampus
        elsif val == 18 or val == 54
          base_png[x,y] = LabelColorAmygdala
        elsif val == 26 or val == 58
          base_png[x,y] = LabelColorAccumbens
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
  lh = {} #LHipp_label
  rh = {} #RHipp_label
  lac = {} #LAccu_label
  rac = {} #RAccu_label
  lam = {} #LAmyg_label
  ram = {} #RAmyg_label
  lca = {} #LCaud_label
  rca = {} #RCaud_label 
  lpa = {} #LPall_label
  rpa = {} #RPall_label 
  lpu = {} #LPuta_label
  rpu = {} #RPuta_label
  lth = {} #LThal_label
  rth = {} #RThal_label
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

def get_slices(cog, anatomico_3d_nifti, structure_3d_nifti, options, label, struct)
  (1..3).each do |sel_dim|

    # Left Hippocampus
    sel_slice = cog.values[sel_dim-1]
    anatomico_2d_slice = get_2d_slice(anatomico_3d_nifti, sel_dim, sel_slice, options[:orientation])
    structure_2d_slice = get_2d_slice(structure_3d_nifti, sel_dim, sel_slice, options[:orientation])
    # Overlay hippocampus label map and flip for display
    labeled_png = generate_label_map_png(anatomico_2d_slice, structure_2d_slice, label).flip_horizontally!
    # Save Labeled PNG
    labeled_png.save("#{options[:outputdir]}/#{struct}_#{sel_dim}_labeled.png")
  end
end

def create_pdf(patfName,patlName,patId,studyDate,options,l_label,r_label,l_volume,r_volume,index_A,structure,all_volumes,all_index_A,patient_age)

  structures_name = {}

  Prawn::Document.generate("#{options[:outputdir]}/report_#{r_label}.pdf") do |pdf|

    #Header image Path 
    pdf.image "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/reporte_pdf/rubycampus/header.png", :width => 630, :height => 70, :at => [-40, 760] #:position => :center

    all_volumes.each  { |k,v| all_volumes[k] = (v.to_f/1000).round(2)}
    l_volume = (l_volume.to_f/1000).round(2)
    r_volume = (r_volume.to_f/1000).round(2)

    structure_names={"lh_cog" => "Hippocampus", "rh_cog" => "Hippocampus", "lac_cog" => "Accumbens", "rac_cog" => "Accumbens", "lam_cog" => "Amygdala", "ram_cog" => "Amygdala", "lca_cog" => "Caudate", "rca_cog" => "Caudate", "lpa_cog" => "Pallidum", "rpa_cog" => "Pallidum", "lpu_cog" => "Putamen", "rpu_cog" => "Putamen", "lth_cog" => "Thalamus", "rth_cog" => "Thalamus"}
    # Title
    #pdf.text "VOLUMETRIC REPORT" , size: 15, style: :bold, :align => :center
    pdf.move_down 35

    # Report Info
    pdf.text "Patient name: #{patfName} #{patlName}    Id: #{patId}    Age: #{patient_age}" , size: 10, style: :bold, :align => :center
    pdf.move_down 20

    # SubTitle RH
    pdf.text "Right #{structure_names[structure]}" , size: 13, style: :bold, :align => :center
    pdf.move_down 5

    # Images RH  
    pdf.image "#{options[:outputdir]}/#{r_label}_3_labeled.png", :width => 200, :height => 200, :position => 95
    pdf.move_up 200
    pdf.image "#{options[:outputdir]}/#{r_label}_2_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.image "#{options[:outputdir]}/#{r_label}_1_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.move_down 20

    # SubTitle LH
    pdf.text "Left #{structure_names[structure]}" , size: 13, style: :bold, :align => :center

    pdf.move_down 5

    # Images LH
    pdf.image "#{options[:outputdir]}/#{l_label}_3_labeled.png", :width => 200, :height => 200, :position => 95
    pdf.move_up 200
    pdf.image "#{options[:outputdir]}/#{l_label}_2_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.image "#{options[:outputdir]}/#{l_label}_1_labeled.png", :width => 150, :height => 100, :position => 295
    pdf.move_down 40

    #Volumes Table New

    volumesTable = [["Right Hippocampus volume:  #{r_volume} cm<sup>3</sup>", "Left Hippocampus volume:  #{l_volume} cm<sup>3</sup>"]]

    pdf.table volumesTable, :position => :center, :cell_style => {align: :center, :inline_format => true, :size => 12}
    pdf.move_down 15
    pdf.text "Asymmetry index: #{sprintf("%.4f",index_A)}" , size: 12, :align => :center

    if structure_names[structure] == options[:main_structure]
      pdf.start_new_page
      pdf.image "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/reporte_pdf/rubycampus/header.png", :width => 630, :height => 70, :at => [-40, 760]
      #pdf.text "Volumetric report", size: 15, style: :bold, :align => :center
      pdf.move_down 35
      pdf.text "Patient name: #{patfName} #{patlName}    Id: #{patId}    Age: #{patient_age}" , size: 10, style: :bold, :align => :center
      pdf.move_down 20

      pdf.text "Subcortical structures" , size: 13, style: :bold, :align => :center
      pdf.move_down 5

      pdf.image "#{options[:outputdir]}/all_labels_3_labeled.png", :width => 300, :height => 300, :position => 30
      pdf.move_up 300
      pdf.image "#{options[:outputdir]}/all_labels_2_labeled.png", :width => 225, :height => 150, :position => 285
      pdf.image "#{options[:outputdir]}/all_labels_1_labeled.png", :width => 225, :height => 150, :position => 285
      pdf.move_down 20

      all_volumesTable = [["<b>Structure*</b> ", "<b>Total volume (cm<sup>3</sup>)</b>", "<b>Right volume (cm<sup>3</sup>)</b>", "<b>Left Volume (cm<sup>3</sup>)</b>", "<b>Asymmetry index*</b>"],
                          ["Hippocampus", "#{(all_volumes[:lhipp_vol]+all_volumes[:rhipp_vol]).round(2)}","#{all_volumes[:rhipp_vol]}","#{all_volumes[:lhipp_vol]}", sprintf("%.4f",all_index_A[0]) ],
                          ["Amygdala", "#{(all_volumes[:lamyg_vol] + all_volumes[:ramyg_vol]).round(2)}","#{all_volumes[:ramyg_vol]}","#{all_volumes[:lamyg_vol]}", sprintf("%.4f",all_index_A[2]) ],
                          ["Accumbens", "#{(all_volumes[:laccu_vol]+all_volumes[:raccu_vol]).round(2)}","#{all_volumes[:raccu_vol]}","#{all_volumes[:laccu_vol]}", sprintf("%.4f",all_index_A[1]) ],
                          ["Caudate", "#{(all_volumes[:lcaud_vol]+all_volumes[:rcaud_vol]).round(2)}","#{all_volumes[:rcaud_vol]}","#{all_volumes[:lcaud_vol]}", sprintf("%.4f",all_index_A[3]) ],
                          ["Pallidum", "#{(all_volumes[:lpall_vol]+all_volumes[:rpall_vol]).round(2)}","#{all_volumes[:rpall_vol]}","#{all_volumes[:lpall_vol]}", sprintf("%.4f",all_index_A[4]) ],
                          ["Putamen", "#{(all_volumes[:lputa_vol]+all_volumes[:rputa_vol]).round(2)}","#{all_volumes[:rputa_vol]}","#{all_volumes[:lputa_vol]}", sprintf("%.4f",all_index_A[5]) ],
                          ["Thalamus", "#{(all_volumes[:ltha_vol]+all_volumes[:rtha_vol]).round(2)}","#{all_volumes[:rtha_vol]}","#{all_volumes[:ltha_vol]}", sprintf("%.4f",all_index_A[6]) ]
                          ]
      pdf.table all_volumesTable, :position => :center, :cell_style => {align: :center, :inline_format => true, :size => 12} 

      pdf.move_down 60
      #pdf.text "* All volumes are reported in cubic centimeters" , size: 8, :align => :center
      pdf.text "* Asymmetry was measured as the right-minus-left volume difference as a fraction of the mean volume" , size: 8, :align => :center


      ############new#############
      pdf.start_new_page
      pdf.image "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/reporte_pdf/rubycampus/header.png", :width => 630, :height => 70, :at => [-40, 760]
      pdf.move_down 35
      pdf.text "Patient name: #{patfName} #{patlName}    Id: #{patId}    Age: #{patient_age}" , size: 10, style: :bold, :align => :center   
      pdf.move_down 5
      pdf.text "Comparision with Control Group", size: 15, style: :bold, :align => :center
      pdf.move_down 10
      pdf.image "#{options[:dicomdir]}/Left-Hippocampus_Right-Hippocampus.png", :scale => 0.43, :at => [0,650]
      pdf.image "#{options[:dicomdir]}/Left-Amygdala_Right-Amygdala.png", :scale => 0.43, :at => [280,650]
      pdf.image "#{options[:dicomdir]}/Left-Caudate_Right-Caudate.png", :scale => 0.43, :at => [0,430]
      pdf.image "#{options[:dicomdir]}/Left-Thalamus_Right-Thalamus.png", :scale => 0.43, :at => [280,430]
      pdf.image "#{options[:dicomdir]}/Left-Putamen_Right-Putamen.png", :scale => 0.43, :at => [0,210]
      pdf.image "#{options[:dicomdir]}/Left-Accumbens_Right-Accumbens.png", :scale => 0.43, :at => [280,210]


      pdf.start_new_page
      pdf.image "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/reporte_pdf/rubycampus/header.png", :width => 630, :height => 70, :at => [-40, 760]
      pdf.move_down 35
      pdf.text "Patient name: #{patfName} #{patlName}    Id: #{patId}    Age: #{patient_age}" , size: 10, style: :bold, :align => :center
      pdf.move_down 5
      pdf.text "Comparision with Control Group", size: 15, style: :bold, :align => :center
      pdf.move_down 10
      pdf.image "#{options[:dicomdir]}/Left-Pallidum_Right-Pallidum.png", :scale => 0.43, :position => :center
      pdf.image "#{options[:dicomdir]}/Grey-Matter_P-Cortex-GM.png", :scale => 0.43, :position => :center
      pdf.image "#{options[:dicomdir]}/v-brain_.png", :scale => 0.43, :position => :center


    end
  end
end   


#### END METHODS ####

beginning_time = Time.now


# CONVERT DICOM TO NIFTI
`mcverter -f fsl -x -d -n -o  #{dicomdir} #{dicomdir}`
#`/Applications/mricron/dcm2nii64 #{dicomdir}`
Dir.mkdir "#{dicomdir}/datafile"


FileUtils.mv Dir.glob('*.nii*'), "#{dicomdir}/datafile"


dirnewname= Dir.entries(dicomdir).select {|entry| File.directory? File.join(dicomdir,entry) and !(entry =='.' || entry == '..') }
dirniipath="#{dicomdir}/#{dirnewname[0]}"
dirniilist=Dir.entries(dirniipath).select {|entry| File.directory? File.join(dirniipath,entry) and !(entry =='.' || entry == '..') }
pathniilist="#{dirniipath}/#{dirniilist[0]}"
original_image=Dir["#{pathniilist}/*.nii*"]

original_image=original_image[0]


#run sienax script 

`sh #{siena_dir}/Reporte_Sienax_auto.sh #{original_image} #{dicomdir}`

# PERFORM BRAIN EXTRACTION
bet = FSL::BET.new(original_image, options[:dicomdir], {fi_threshold: 0.5, v_gradient: 0})
bet.command
bet_image = bet.get_result

case options[:orientation]
when 'sagital'
  `fslswapdim #{bet_image} -z -x y #{bet_image}`
when 'coronal'
  `fslswapdim #{bet_image} x -z y #{bet_image}`
end


# PERFORM 'FIRST' SEGMENTATION
first = FSL::FIRST.new(bet_image, "#{options[:outputdir]+"/FIRST"}", {already_bet:true, structure: 'L_Hipp,R_Hipp,L_Accu,R_Accu,L_Amyg,R_Amyg,L_Caud,R_Caud,L_Pall,R_Pall,L_Puta,R_Puta,L_Thal,R_Thal'})
first.command
first_images = first.get_result


# Get center of gravity coordinates
cog_coords = FSL::Stats.new(first_images[:origsegs], true, {cog_voxel: true}).command.split
lh_cog, rh_cog, lac_cog, rac_cog, lam_cog, ram_cog, lca_cog, rca_cog, lpa_cog, rpa_cog, lpu_cog, rpu_cog, lth_cog, rth_cog = coord_map(cog_coords)
puts "Left Hippocampus center of gravity voxel coordinates: #{lh_cog}"
puts "Right Hippocampus center of gravity voxel coordinates: #{rh_cog}"


#test get volumen
struct_label.each do |key,value|
  volumes.each do |k,v|
    if volumes[k] == -1
      volumes[k] = get_volumes(value,first_images)
      break
    end
  end
end
#end test

# indix of assymetry:  A=2*((Vr-Vl)/(Vr+Vl))
index_A = []

volumes_label_keys = volumes.keys

(0..6).each do |i|
  index_A[i] = 0.5*((volumes[volumes_label_keys[i*2+1]].to_f-volumes[volumes_label_keys[i*2]].to_f)/(volumes[volumes_label_keys[i*2+1]].to_f+volumes[volumes_label_keys[i*2]].to_f))
end 

File.open("subcortial_vol.csv", "a+") do |file|
  file << "lhipp_vol,rhipp_vol,laccu_vol,raccu_vol,lamyg_vol,ramyg_vol,lcaud_vol,rcaud_vol,lpall_vol,rpall_vol,lputa_vol,rputa_vol,ltha_vol,rtha_vol\n"
  file << "#{volumes[:lhipp_vol]},#{volumes[:rhipp_vol]},#{volumes[:laccu_vol]},#{volumes[:raccu_vol]},#{volumes[:lamyg_vol]},#{volumes[:ramyg_vol]},#{volumes[:lcaud_vol]},#{volumes[:rcaud_vol]},#{volumes[:lpall_vol]},#{volumes[:rpall_vol]},#{volumes[:lputa_vol]},#{volumes[:rputa_vol]},#{volumes[:ltha_vol]},#{volumes[:rtha_vol]}"
end

# Decompress files
anatomico_nii = decompress(bet_image)
structure_nii= decompress(first_images[:firstseg])

# Set  nifti file
anatomico_3d_nifti = read_nifti(anatomico_nii)
structure_3d_nifti = read_nifti(structure_nii)


coord_struc = {}
coord_struc["lh_cog"] = lh_cog
coord_struc["rh_cog"] = rh_cog
coord_struc["lac_cog"] = lac_cog
coord_struc["rac_cog"] = rac_cog
coord_struc["lam_cog"] = lam_cog
coord_struc["ram_cog"] = ram_cog
coord_struc["lca_cog"] = lca_cog
coord_struc["rca_cog"] = rca_cog
coord_struc["lpa_cog"] = lpa_cog
coord_struc["rpa_cog"] = rpa_cog
coord_struc["lpu_cog"] = lpu_cog
coord_struc["rpu_cog"] = rpu_cog
coord_struc["lth_cog"] = lth_cog
coord_struc["rth_cog"] = rth_cog


#test get slices
cont = 0
struct_label_keys=struct_label.keys
coord_struc.keys.each do |k|
  get_slices(coord_struc[k], anatomico_3d_nifti, structure_3d_nifti, options, struct_label[struct_label_keys[cont]] , k)
  cont += 1
end

get_slices(coord_struc["lpa_cog"], anatomico_3d_nifti, structure_3d_nifti, options, "all_labels", "all_labels")

#end get slices

## test get_pdf
coord_struc_keys=coord_struc.keys
volumes_keys=volumes.keys


#make figure
get_csv(options[:dicomdir], patient_age)

#main_structure = "Hipocampo"

cont=0
(0..volumes.keys.size-2).each do |i|
  if (i % 2) == 0
    create_pdf(patfName,patlName,patId,studyDate,options,coord_struc_keys[cont],coord_struc_keys[cont+1],volumes[volumes_keys[i]],volumes[volumes_keys[i+1]],index_A[i/2],coord_struc_keys[i],volumes,index_A,patient_age)
    cont += 2
  end
end



  ##end test get_pdf
end_time = Time.now
puts "Time elapsed #{(end_time - beginning_time)} seconds"


