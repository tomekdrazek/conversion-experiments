
require_relative 'test_helper.rb'
require_relative '../lib/spv/spv_convert'

class TestSPVConvert < Test::Unit::TestCase

  include SPV::Convert

  def setup
    FileUtils.rm_rf "./tmp/test"
  end

  def teardown
  end

  def test_cache_generation
    cmyk_to_cache(fixture_path("page.jpg"), "./tmp/test")
    assert_true true
  end
end
