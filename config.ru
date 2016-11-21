# config.ru (run with rackup)
require_relative 'lib/spv/spv_rest_api.rb'
run SPV::RestAPI
