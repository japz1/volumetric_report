require 'sinatra/base'
require 'pony'
require 'sidekiq'
require 'sidekiq/api'
require 'sidekiq/web'
require 'dcm2nii-ruby'
require 'fsl-ruby'
require 'narray'
require 'nifti'
require 'chunky_png'
require 'prawn'
require 'zip'
require 'byebug'
require 'optparse'
require 'prawn'
require 'prawn/table'
require 'dicom'
include DICOM 
require 'fileutils'
require 'byebug'
require 'find'

require_relative 'helpers/init'
require_relative 'lib/workers/process_image.rb'


Rack::Utils.multipart_part_limit = 0

class VolumetricReport < Sinatra::Base

 
get "/upload" do
  erb :upload
end 

get "/index" do
  erb :index
end

get '/login' do
  erb :login_form
end

post "/upload" do

  now = Time.now.to_i.to_s
  path = "uploads/" + now + params['myfile'][:filename]
  zipfolder = "/dicom/zip/"
  unzipfolder = "/dicom/unzip/"
  filename = params['myfile'][:tempfile].read
  name = now + params['myfile'][:filename]

  File.open(path, "w") do |f|
    f.write(filename)
  end
  
  ProcessImage.perform_async(path, zipfolder, name, unzipfolder, now, params)

  return "uploads/#{params['myfile'][:filename]}"
  return
end

end
