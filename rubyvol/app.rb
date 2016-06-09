
require 'sinatra'
require 'pony'

class HelloWorldApp < Sinatra::Base
  get '/' do
    "Hello, world!"
  end

# Handle GET-request (Show the upload form)
get "/upload" do
  erb :upload
end      
    
# Handle POST-request (Receive and save the uploaded file)
post "/upload" do 
  File.open('uploads/' + params['myfile'][:filename], "w") do |f|
    f.write(params['myfile'][:tempfile].read)
  end
  
  
  Pony.mail({
		:to => 'catalinabustam@gmail.com',
		:subject => "prueba imagen",
		:body => "prueba",
		:via => :smtp,
		:attachments => {File.basename("uploads/#{params['myfile'][:filename]}") => File.read("uploads/#{params['myfile'][:filename]}")},
		:via_options => {
		 :address              => 'smtp.gmail.com',
		 :port                 => '587',
		 :enable_starttls_auto => true,
		 :user_name            => 'alertasiatm@gmail.com',
		 :password             => 'AlertasIatm2015',
		 :authentication       => :plain, 
		 :domain               => "localhost.localdomain"
	       }
        })
  return "uploads/#{params['myfile'][:filename]}"
  return
end

end