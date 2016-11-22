require 'sinatra/base'
require "sinatra/json"
require_relative '../spv'

module SPV
  class RestAPI < Sinatra::Application

    use Rack::Auth::Basic, "Restricted Area" do |username, password|
      begin
        @@processor = SPV::Processor.new(username)
        @@processor.authorized?(password)
      rescue
        false
      end
    end

    get '/test' do
      "Hello world"
    end

    get '/page/:id' do |id|
      @@processor.get(SPV::parse_ids(id))
      json @@processor.report
      # {}.to_json
    end

    put '/page/:id' do |id|

    end

    delete '/page/:id' do |id|

    end

    put '/pages' do
      p = SPV::Processor.new(app)
      raise "No source document specified" if args[0].nil?
      p.add( args[0], options.sel, SPV::parse_ids(options.ids, false) )
      p.process_queue
      p.output(p.report, $type)
    end

    # start the server if ruby file executed directly
    run! if app_file == $0
  end
end
