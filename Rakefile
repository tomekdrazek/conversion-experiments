require 'rake/testtask'
require_relative 'lib/spv'

Rake::TestTask.new do |t|
  t.test_files = FileList['test/unit/*_test.rb']
  # t.verbose = true
end

namespace :spv do
  desc "Start web API server"
  task :server do
    require_relative 'lib/spv/spv_rest_api'
    SPV::RestAPI.run!
  end


  desc "Start backend conversion"
  task :run do
    system "bundle exec sidekiq -r ./lib/spv/spv_worker.rb"
  end

  desc "Start backend service"
  task :start do
    puts "Starting backend processing deamon."
    system "bundle exec sidekiq -r ./lib/spv/spv_worker.rb -d -L log/spv.log -P tmp/spv.pid"
    puts "Starting REST API web server."
    system "bundle exec thin start -d -p 8080 -l log/spv.api.log -P tmp/spv.api.pid"
  end

  desc "Stop backed service"
  task :stop do
    if File.exist? "tmp/spv.pid"
      pid = File.read("tmp/spv.pid").chomp
      system "kill #{pid}"
      FileUtils.rm "tmp/spv.pid"
    end
    if File.exist? "tmp/spv.api.pid"
      pid = File.read("tmp/spv.api.pid").chomp
      system "kill #{pid}"
    end
  end
end
