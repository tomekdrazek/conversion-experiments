
require_relative 'test_helper.rb'
require_relative '../lib/spv/spv_convert'
require 'json'
# This test is used to test low-level conversion routines in the SPV::Convert module.

class TestSPVConvert < Test::Unit::TestCase
  include SPV::Convert

  def setup
    FileUtils.rm_rf './tmp/test'
  end

  def teardown
  end

  # Test page selection mechanism.
  def _test_page_sel
    assert_equal [1], _get_page_sel("1")
    assert_equal [1,2], _get_page_sel("1,2")
    assert_equal [1,5,4], _get_page_sel("1,5,4")
    assert_equal [1,2,3,4], _get_page_sel("1~4")
    assert_equal [16], _get_page_sel("-1", 16)
    assert_equal [15,16], _get_page_sel("-2~-1", 16)
    assert_equal [1,2,15,16], _get_page_sel("1,2,-2~-1", 16)
    assert_equal [1,15,16,2], _get_page_sel("1,-2,-1,2", 16)
    assert_equal (1..16).to_a, _get_page_sel("1~-1", 16)
    assert_equal [1], _get_page_sel("-1", 0)
    assert_equal [2], _get_page_sel("-1", 2)
    assert_equal [1], _get_page_sel("-2", 2)
  end

  # NOT IMPLEMENTED YET
  def _test_bitmap_conversion
    ch = Dir.mktmpdir do |tmp_dir|
      out = _convert_bmp_page(fixture_path('colors-spot-1.tif'), tmp_dir)
      _merge_channels(out, './tmp/colors-spot/page1-tif-', "001")
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
    # cmyk_to_cache(fixture_path('page.jpg'), './tmp/test')
    # assert_true true
  end

  def test_pdf_preflight
    out = _check_pdf(fixture_path('colors-spot.pdf'))
    assert_equal 2, out.count
    assert_equal 2481, out[1]["MediaBox"]["wpx"]
    assert_equal 3508, out[1]["MediaBox"]["hpx"]
    out = _check_pdf(fixture_path('Lorem-ipsum.pdf'))
    assert_equal 8, out.count
    # puts out.to_json
    out = _apply_sel(out, "1~4,-1", ['page1', 'page2', 'page3', nil, 'page8'])
    pp out
    assert_equal 5, out.count
  end

  def _test_pdf_conversion
    # This test low level PDF to output bitmap cache conversion:
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
