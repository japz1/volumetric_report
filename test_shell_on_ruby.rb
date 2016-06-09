puts "this is an example"

#original_image=original_image[0]

# PERFORM BRAIN EXTRACTION
#bet = FSL::BET.new(original_image, options[:dicomdir], {fi_threshold: 0.5, v_gradient: 0})

system "./Reporte_Sienax_auto.sh /Users/enterprise/Desktop/prueba_dcmtonii/axial/SIMPLE_VOL_AX/00040005166_1_801_SIMPLE_VOL_AX_20140604 /Users/enterprise/Desktop/prueba_dcmtonii/axial/SIMPLE_VOL_AX/00040005166_1_801_SIMPLE_VOL_AX_20140604/JIMENEZ_MEJIA_GUSTAVO_ADOLFO_20140604_00040005166_1_801_SIMPLE_VOL_AX_SENSE_SIMPLE_VOL_AX.nii"
