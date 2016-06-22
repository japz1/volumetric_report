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
require 'csv'
require 'gnuplot'
require 'sinatra/strong-params'
require 'sinatra/flash'
require 'dotenv'

Dotenv.load

require_relative 'helpers/init'
require_relative 'lib/workers/process_image.rb'


Rack::Utils.multipart_part_limit = 0

class VolumetricReport < Sinatra::Base
  enable :sessions

  register Sinatra::StrongParams
  register Sinatra::Flash

  set :show_exceptions, false

get "/upload" do
  erb :index
end 


post "/upload", allows: [:orientation, :structure, :patage, :email, :dicomfile], needs: [:orientation, :structure, :patage, :email, :dicomfile] do 
  now = Time.now.to_i.to_s
  now_t = Time.now
  flash[:notice] = "The image has been uploaded at #{Time.now} you will receive the report in some hours at #{params['email']}" 
  path = "uploads/" + now + params['dicomfile'][:filename]
  zipfolder = "/dicom/zip/"
  unzipfolder = "/dicom/unzip/"
  filename = params['dicomfile'][:tempfile].read
  name = now + params['dicomfile'][:filename]

  File.open(path, "w") do |f|
    f.write(filename)
  end
  ProcessImage.perform_async(path, zipfolder, name, unzipfolder, now, params, now_t)
  redirect "/upload"
end

error RequiredParamMissing do
  flash[:error] = "Error some required Params missing"
  redirect "/upload"
end

end
