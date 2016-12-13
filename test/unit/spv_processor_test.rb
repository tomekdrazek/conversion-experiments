# This test is used to conversion processor routines in the SPV::Processor class.
# @author Tomek Drazek <tomek@newshubmedia.com>

require_relative '../test_helper.rb'
require_relative '../../lib/spv'
require 'json'

class TestSPVProcessor < Test::Unit::TestCase

  def setup
    FileUtils.rm_rf './public/sample'
  end

  def teardown

  end

  def test_config
    p = SPV::Processor.new("sample")
    assert_equal 'sample', p.app
    assert_equal 'public/sample/pages', p.config['repository']
    assert_raises do
      p.app="missing"
    end
  end

  # The method test verification of the current page version and updates the preflight results with previous versions, that are already created in the sample configuration
  # This test does not process queue actually!
  def test_version_add
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors-spot.pdf'), nil, ['page-1', 'page-2'])
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    assert_true File.exist?('public/sample/pages/page-1.json')
    assert_true File.exist?('public/sample/pages/page-2.json')
    assert_true File.directory?('public/sample/pages/page-1')
    assert_true File.directory?('public/sample/pages/page-2')
    assert_equal 3, p.queue.count
  end

  # The test of processing of the queue with adding new entries.
  # This test perfomers processing of the queue and thus may take a little longer
  def test_processing
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    assert_equal 1, p.queue.count
    p.process_queue(false)
    assert_equal 2, Dir.glob('public/sample/pages/page-1/1-*.jpg').count
    assert_equal 1, Dir.glob('public/sample/pages/page-1/thb-*.jpg').count
    p.add(fixture_path('colors-spot.pdf'), nil, ['page-1', 'page-2'])
    assert_equal 2, p.queue.count
    p.process_queue(false)
    assert_equal 2, Dir.glob('public/sample/pages/page-1/2-*.jpg').count
    assert_equal 2, Dir.glob('public/sample/pages/page-1/thb-*.jpg').count
    assert_equal 2, Dir.glob('public/sample/pages/page-2/1-*.jpg').count
    assert_equal 1, Dir.glob('public/sample/pages/page-2/thb-*.jpg').count

    # TODO: Add and ensure correctness with test of page adding based on bitmaps:
    p.add(fixture_path('colors-cmyk-fogra.tiff'), nil, ['page-1'])


  end

  def test_list
    p = SPV::Processor.new('sample')
    p.add(fixture_path('colors.pdf'), nil, ['page-1'])
    p.list("*")
    assert_equal 1, p.report.count
  end

  def test_intents
    p = SPV::Processor.new('sample')
    p.intent_set("sample-intent", fixture_path("ISOcoated_v2_eci.icc"))
    p.intent_set("iso-coated", fixture_path("ISOcoated_v2_eci.icc"))
    assert_equal 2, p.intents.count
    p.intent_del("sample-intent")
    assert_equal 1, p.intents.count
    p.intent_list()
    assert_equal 1, p.intents.count
  end

  def test_displays
    p = SPV::Processor.new('sample')
    p.display_set("wide-gamut", fixture_path("WideGamutRGB.icc"))
    p.display_set("sample-display", fixture_path("WideGamutRGB.icc"))
    assert_equal 2, p.displays.count
    p.display_del("sample-display")
    assert_equal 1, p.displays.count
    p.display_list()
    assert_equal 1, p.displays.count
  end
end
