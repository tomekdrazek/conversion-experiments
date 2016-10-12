
require_relative 'test_helper.rb'
require_relative '../lib/spv/spv_convert'

class TestSPVConvert < Test::Unit::TestCase
  include SPV::Convert

  def setup
    FileUtils.rm_rf './tmp/test'
  end

  def teardown
  end

  def test_cache_generation
    cmyk_to_cache(fixture_path('page.jpg'), './tmp/test')
    assert_true true
  end

  def test_pdf_conversion
    ch = Dir.mktmpdir do |tmp_dir|
      out = _convert_pdf_page(fixture_path('colors-spot.pdf'), tmp_dir, 1)
      _merge_channels(out, './tmp/colors-spot/page1', "001")
    end
    assert_equal 2, ch.count
    assert_equal 3, ch[0][:channels].count
    assert_true ch[0][:channels].include? :cyan
    assert_true ch[0][:channels].include? :magenta
    assert_true ch[0][:channels].include? :yellow
    assert_true File.exists? ch[0][:img]
    assert_equal 1, ch[1][:channels].count
    assert_true ch[1][:channels].include? :black
    assert_true File.exists? ch[1][:img]
    ch = Dir.mktmpdir do |tmp_dir|
      out = _convert_pdf_page(fixture_path('colors-spot.pdf'), tmp_dir, 2)
      _merge_channels(out, './tmp/colors-spot/page2', "001")
    end
    assert_equal 2, ch.count
    assert_equal 3, ch[0][:channels].count
    assert_true ch[0][:channels].include? :cyan
    assert_true ch[0][:channels].include? :magenta
    assert_true ch[0][:channels].include? :yellow
    assert_true File.exists? ch[0][:img]
    assert_equal 2, ch[1][:channels].count
    assert_true ch[1][:channels].include? :black
    assert_true ch[1][:channels].include? "Spot 1"
    assert_true File.exists? ch[1][:img]
    
    # _convert_page("./tests/fixtures/Olivia-2012-07-011.pdf", "./tmp/test/ol-01.tif", 1)
    # _convert_page(page, "./tmp/test/page-no-cms.tif", 1)
    # _convert_page(page, "./tmp/test/page.tif", 1, {
    #   "-sDefaultCMYKProfile": fixture_path("ISOcoated_v2_eci.icc"),
    #   "-sOutputICCProfile": fixture_path("ISOcoated_v2_eci.icc")
    #   } )
  end
end
