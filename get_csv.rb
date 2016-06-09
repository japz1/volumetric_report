require 'csv'
require 'byebug'

path = "/Users/enterprise/Documents/IATM/SIIM_2016/new_process/resultadosestudioclasificacindevolmenesestructurales/csv_files"
age=20
data = Hash.new

structures = ["L_accum","R_accum","L_amyg","R_amyg","L_caud","R_caud",
              "L_hyp","R_hyp","L_pall","R_pall","L_put","R_put","L_thal","R_thal",
              "cort_gmv","grayv","brainv","whitemv","csf"]
structures.each do |file|
  CSV.foreach("#{path}/#{file}.csv") do |row|
    data["#{file}"] = row if row[0] == age.to_s
    puts data if row[0] == age.to_s
  end
end
byebug
puts "fin"

