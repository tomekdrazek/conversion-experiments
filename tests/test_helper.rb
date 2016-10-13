STDOUT.sync = true  # Sync the IO upon test to get results on console immediatly
require 'test/unit'
require 'pp'

def fixture_path(path = "")
  File.absolute_path(File.join(File.dirname(__FILE__), "fixtures", path))
end
