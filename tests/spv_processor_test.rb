# This test is used to conversion processor routines in the SPV::Processor class.
# @author Tomek Drazek <tomek@newshubmedia.com>

require_relative 'test_helper.rb'
require_relative '../lib/spv'
require 'json'

class TestSPVProcessor < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf './public/sample'
  end
  def teardown

  end

  def _test_config
    p = SPV::Processor.new("sample")
    assert_equal 'sample', p.app
    assert_equal 'public/sample', p.config['repository']
    assert_raises do
      p.app="missing"
    end
  end

  # The method test verification of the current page version and updates the preflight results with previous versions, that are already created in the sample configuration
  # @todo Not implemented.
  def test_version_add
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors-spot.pdf'), nil, ['page-1', 'page-2'])
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    p.process_queue
  end

end
