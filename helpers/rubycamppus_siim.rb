#!/usr/bin/env ruby

def rubyvol(dicomdir, orientation, main_structure, pat_age)

  siena_dir = "helpers/"
  
  image = get_dicomfile(dicomdir)
  dcm = DObject.read(image)
  study_info = dcm.value("0008,1030")
  pat_name = dcm.value("0010,0010")
  pat_id = dcm.value("0010,0020")
  study_date = dcm.value("0008,0020")
  accession_no = dcm.value("0008,0050")
  patient_age = dcm.value("0010,1010") ? dcm.value("0010,1010")[0..2].to_i : pat_age
  patfname = pat_name[(pat_name =~ /\^/)+1, pat_name.length]
  patlname = pat_name[0,pat_name =~ /\^/]
  
  struct_label = {lhipp_label: 17, rhipp_label: 53, laccu_label: 26, raccu_label: 58, lamyg_label: 18, ramyg_label: 54, lcaud_label: 11, rcaud_label: 50, lpall_label: 13, rpall_label: 52, lputa_label: 12, rputa_label: 51, lthal_label: 10, rthal_label: 49 }
  volumes = {lhipp_vol: -1, rhipp_vol: -1, laccu_vol: -1, raccu_vol: -1, lamyg_vol: -1, ramyg_vol: -1, lcaud_vol: -1, rcaud_vol: -1, lpall_vol: -1, rpall_vol: -1, lputa_vol: -1, rputa_vol: -1, ltha_vol: -1, rtha_vol: -1}
  
  label_color = {}
  label_color['general'] = ChunkyPNG::Color.rgb(255,0,0)
  label_color["talamo"] = ChunkyPNG::Color.rgb(0,118,14)
  label_color["caudate"] = ChunkyPNG::Color.rgb(122,186,220)
  label_color["putamen"] = ChunkyPNG::Color.rgb(236,13,176)
  label_color["padillum"] = ChunkyPNG::Color.rgb(12,48,255)
  label_color["hippocampus"] = ChunkyPNG::Color.rgb(220,216,20)
  label_color["amygdala"] = ChunkyPNG::Color.rgb(103,255,255)
  label_color["accumbens"] = ChunkyPNG::Color.rgb(255,165,0)
  
  
  #### END METHODS ####
  
  beginning_time = Time.now
  
  
  # CONVERT DICOM TO NIFTI
  Dir.mkdir "#{dicomdir}/nifti" unless File.directory?("#{dicomdir}/nifti")

  niftidir = "#{dicomdir}/nifti"

  `mcverter -f fsl -x -d -n -o  #{niftidir} #{dicomdir}`
  
  original_image = get_niftifile(niftidir)

  Dir.mkdir "#{dicomdir}/datafile" unless File.directory?("#{dicomdir}/datafile")

  outputdir = "#{dicomdir}/datafile"
  
  FileUtils.cp original_image, "#{dicomdir}/datafile"
  
  #run sienax script 
  
  `sh #{siena_dir}/Reporte_Sienax_auto.sh #{original_image} #{outputdir}`
  
  # PERFORM BRAIN EXTRACTION

  bet = FSL::BET.new(original_image, outputdir, {fi_threshold: 0.5, v_gradient: 0})
  bet.command
  bet_image = bet.get_result
  puts bet_image
  
  case orientation
  when 'sagital'
    `fslswapdim #{bet_image} -z -x y #{bet_image}`
  when 'coronal'
    `fslswapdim #{bet_image} x -z y #{bet_image}`
  end
  
  
  # PERFORM 'FIRST' SEGMENTATION
  first = FSL::FIRST.new(bet_image, "#{outputdir}"+"/FIRST", {already_bet:true, structure: 'L_Hipp,R_Hipp,L_Accu,R_Accu,L_Amyg,R_Amyg,L_Caud,R_Caud,L_Pall,R_Pall,L_Puta,R_Puta,L_Thal,R_Thal'})
  puts bet_image
  puts "#{outputdir}"+"/FIRST"
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
    index_A[i] = 2*((volumes[volumes_label_keys[i*2+1]].to_f-volumes[volumes_label_keys[i*2]].to_f)/(volumes[volumes_label_keys[i*2+1]].to_f+volumes[volumes_label_keys[i*2]].to_f))
  end 
  
  File.open("#{outputdir}/subcortial_vol.csv", "a+") do |file|
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
    get_slices(coord_struc[k], anatomico_3d_nifti, structure_3d_nifti, orientation, outputdir, struct_label[struct_label_keys[cont]] , k, label_color)
    cont += 1
  end
  
  get_slices(coord_struc["lpa_cog"], anatomico_3d_nifti, structure_3d_nifti, orientation, outputdir, "all_labels", "all_labels", label_color)
  
  #end get slices
  
  ## test get_pdf
  coord_struc_keys=coord_struc.keys
  volumes_keys=volumes.keys
  
  
  #make figure
  get_csv(outputdir, patient_age, outputdir)
  #main_structure = "Hipocampo"
  
  cont=0
  (0..volumes.keys.size-2).each do |i|
    if (i % 2) == 0
      create_pdf(patfname,patlname,pat_id,study_date, outputdir, main_structure, coord_struc_keys[cont],coord_struc_keys[cont+1],volumes[volumes_keys[i]],volumes[volumes_keys[i+1]],index_A[i/2],coord_struc_keys[i],volumes,index_A)
      cont += 2
    end
  end
  
  pdfname = "#{outputdir}/volumetric_report_#{pat_id}_#{main_structure}.pdf"

  return  pdfname 
    ##end test get_pdf
  end_time = Time.now
  puts "Time elapsed #{(end_time - beginning_time)} seconds"
  
end
  
