class ProcessImage
  include Sidekiq::Worker

  def perform(file, zip, name, unzip, timestr, params, now_t)
    FileUtils.cp(file, zip + name)
    orientation = params["orientation"]
    main_structure = params["structure"]
    pat_age = params["patage"]
    dicomfolder = unzip + timestr
    extract_zip(zip + name, unzip + timestr)
    file = rubyvol(unzip + timestr, orientation, main_structure, pat_age)
    send_email(params["email"], file, file, now_t)
  end
  
  def extract_zip(file, destination)
    FileUtils.mkdir_p(destination)
   
    Zip::File.open(file) do |zip_file|
      zip_file.each do |f|
        fpath = File.join(destination, f.name)
        ext = File.extname(f.name)
        zip_file.extract(f, fpath) unless File.exist?(fpath)
      end
    end
  end
  
end
  
