def send_email(to, name, file, now_t)
  Pony.mail({
    :to => to,
    :subject => "Brain Volumetric Report",
    :body => "A request has been made to create a volumetric report at " + now_t + ", On the attachments you will find the generated report",
    :via => :smtp,
    :attachments => {File.basename(name) => File.read(file)},
    :via_options => {
     :address              => 'smtp.gmail.com',
     :port                 => '587',
     :enable_starttls_auto => true,
     :user_name            => ENV['MAILUSER_NAME'],
     :password             => ENV['PASSWORD'],
     :authentication       => :plain, 
     :domain               => "localhost.localdomain"
         }
        })
end
