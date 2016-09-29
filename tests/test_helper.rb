require 'test/unit'
require 'pp'

def fixture_path(path = "")
  File.absolute_path(File.join(File.dirname(__FILE__), "fixtures", path))
end
