# config.ru
require './app.rb'

run Rack::URLMap.new('/' => VolumetricReport, '/sidekiq' => Sidekiq::Web)
