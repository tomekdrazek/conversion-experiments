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
  # This test does not process queue actually!
  def _test_version_add
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors-spot.pdf'), nil, ['page-1', 'page-2'])
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    assert_true File.exists?('public/sample/page-1.json')
    assert_true File.exists?('public/sample/page-2.json')
    assert_true File.directory?('public/sample/page-1')
    assert_true File.directory?('public/sample/page-2')
    assert_equal 3, p.queue.count
  end

  # The test of processing of the queue with adding new entries.
  # This test perfomers processing of the queue and thus may take a little longer
  def _test_processing
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    assert_equal 1, p.queue.count
    p.process_queue(false)
    assert_equal 2, Dir.glob('public/sample/page-1/*.jpg').count
    p.add(fixture_path('colors-spot.pdf'), nil, ['page-1', 'page-2'])
    assert_equal 2, p.queue.count
    p.process_queue(false)
    assert_equal 4, Dir.glob('public/sample/page-1/*.jpg').count
    assert_equal 2, Dir.glob('public/sample/page-2/*.jpg').count
  end
end
