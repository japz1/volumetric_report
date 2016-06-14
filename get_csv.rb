require 'csv'
require 'byebug'
require_relative 'get_graph.rb'

def get_csv(path_csv,age)
  path = "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/reporte_pdf/rubycampus/csv_files" #volumes healthy volunteer
  #path_csv volumes patient

  data = Hash.new
  data_patient = Hash.new

  #get volumes healthy volunteer
  structures = ["lhipp_vol", "rhipp_vol", "laccu_vol", "raccu_vol", "lamyg_vol", "ramyg_vol", "lcaud_vol", 
                "rcaud_vol", "lpall_vol", "rpall_vol", "lputa_vol", "rputa_vol", "ltha_vol", "rtha_vol",
                "v-grey","v-pgrey","v-white","v-brain","v-vcsf"]

  structures_name = [ "Left-Hippocampus", "Right-Hippocampus", "Left-Accumbens", "Right-Accumbens", "Left-Amygdala", "Right-Amygdala", "Left-Caudate", 
                      "Right-Caudate", "Left-Pallidum", "Right-Pallidum", "Left-Putamen", "Right-Putamen", "Left-Thalamus", "Right-Thalamus",
                      "Grey-Matter","P-Cortex-GM","White-Matter","v-brain","v-vcsf"]

  structures.each do |file|
    CSV.foreach("#{path}/#{file}.csv") do |row|
      data["#{file}"] = row if row[0] == age.to_s
      puts data if row[0] == age.to_s
    end
  end

  #get volumes patient

  general_vol = CSV.read("#{path_csv}/reporte_volumenes_sienax.csv")
  subcortical_vol = CSV.read("#{path_csv}/subcortial_vol.csv")



  (0..13).each { |var| data_patient["#{structures[var]}"] = (subcortical_vol[1][var].to_f * general_vol[1][0].to_f).round(2) } #normalize
  (0..4).each { |var| data_patient["#{structures[var+14]}"] = general_vol[1][(var*2)+1].to_f }

  #subcortical graph
  (0..6).each { |var| graph([data[data.keys[var*2]],data[data.keys[var*2+1]]], [data_patient[data_patient.keys[var*2]], data_patient[data_patient.keys[var*2+1]]], structures_name[var*2..var*2+1], path_csv) }

  #cortical graph
  graph([data[data.keys[14]],data[data.keys[15]],data[data.keys[16]]], [data_patient[data_patient.keys[14]],data_patient[data_patient.keys[15]], data_patient[data_patient.keys[16]]], structures_name[14..16], path_csv)

  #brain graph

  graph([data[data.keys[17]]], [data_patient[data_patient.keys[17]]], [structures_name[17]], path_csv)

  puts "end get_csv"
end

