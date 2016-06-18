def send_email(to, name, file)
  Pony.mail({
    :to => to,
    :subject => "prueba imagen",
    :body => "prueba",
    :via => :smtp,
    :attachments => {File.basename(name) => File.read(file)},
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
end
