# This test is used to test low-level conversion routines in the SPV::Convert module.
# This module is a API for the command line utilities to prepare conversion and verification routines
# @author Tomek Drazek <tomek@newshubmedia.com>

require_relative '../test_helper.rb'
require_relative '../../lib/spv/spv_convert'

class TestSPVConvert < Test::Unit::TestCase
  include SPV::Convert

  def setup
    FileUtils.rm_rf './tmp'
  end

  def teardown

  end

  # Tests page selection mechanism.
  def test_page_sel
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

  # Tests PDF page preflight
  def test_pdf_preflight
    out = _check_pdf(fixture_path('colors-spot.pdf'))
    assert_equal 2, out.count
    assert_equal 2481, out[1]['geometry']['mediabox']['wpx']
    assert_equal 3508, out[1]['geometry']['mediabox']['hpx']
    out = _check_pdf(fixture_path('Lorem-ipsum.pdf'))
    assert_equal 8, out.count
    out = _apply_sel(out, "1~4,-1", ['page1', 'page2', 'page3', nil, 'page8'])
    assert_equal 5, out.count
  end

  # Tests bitmap page preflight
  def test_bmp_preflight
    out = _check_bmp(fixture_path('colors-cmyk-noprofile.tiff'))
    assert_equal 1, out.count
    assert_equal 2480, out[0]['geometry']['mediabox']['wpx']
    assert_equal 3507, out[0]['geometry']['mediabox']['hpx']
  end

  # The worker that performs PDF to cache conversion (the routine normally lunched in the background)
  def test_pdf_conversion
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
    assert_true File.exist? ch[0][:img]
    assert_equal 1, ch[1][:channels].count
    assert_true ch[1][:channels].include? :black
    assert_true File.exist? ch[1][:img]
    ch = Dir.mktmpdir do |tmp_dir|
      out = _convert_pdf_page(fixture_path('colors-spot.pdf'), tmp_dir, 2)
      _merge_channels(out, './tmp/colors-spot/page2', "001")
    end
    assert_equal 2, ch.count
    assert_equal 3, ch[0][:channels].count
    assert_true ch[0][:channels].include? :cyan
    assert_true ch[0][:channels].include? :magenta
    assert_true ch[0][:channels].include? :yellow
    assert_true File.exist? ch[0][:img]
    assert_equal 2, ch[1][:channels].count
    assert_true ch[1][:channels].include? :black
    assert_true ch[1][:channels].include? "Spot 1"
    assert_true File.exist? ch[1][:img]

    # _convert_page("./tests/fixtures/Olivia-2012-07-011.pdf", "./tmp/test/ol-01.tif", 1)
    # _convert_page(page, "./tmp/test/page-no-cms.tif", 1)
    # _convert_page(page, "./tmp/test/page.tif", 1, {
    #   "-sDefaultCMYKProfile": fixture_path("ISOcoated_v2_eci.icc"),
    #   "-sOutputICCProfile": fixture_path("ISOcoated_v2_eci.icc")
    #   } )
  end

  # Test bitmap conversion
  # @todo Checking of color managment variants during conversion.
  def test_bmp_conversion
    ch = Dir.mktmpdir do |tmp_dir|
      out = _convert_bmp_page(fixture_path('colors-cmyk-noprofile.tiff'), tmp_dir)
      _merge_channels(out, './tmp/colors-spot/colors-cmyk-tif', "001")
    end
    assert_equal 2, ch.count
    assert_equal 3, ch[0][:channels].count
    assert_true ch[0][:channels].include? :cyan
    assert_true ch[0][:channels].include? :magenta
    assert_true ch[0][:channels].include? :yellow
    assert_true File.exist? ch[0][:img]
    assert_equal 1, ch[1][:channels].count
    assert_true ch[1][:channels].include? :black
    assert_true File.exist? ch[1][:img]
  end

  # Test probes conversion
  def test_probes_conversion
    _convert_probes(fixture_path("cmyk-64.tif"), "./tmp/probes.jpg", fixture_path("ISOcoated_v2_eci.icc"), fixture_path("WideGamutRGB.icc") )
    assert_true File.exist?("./tmp/probes.jpg")
  end

  # Test PDF thumbnail creation
  def test_pdf_thb
    out = _thb_pdf(fixture_path('colors-spot.pdf'), "./tmp/thumb", 1)
    assert_true File.exist?(out)
  end

  # Test bitmap thumbnail creation
  def test_bmp_thb
    out = _thb_bmp(fixture_path('colors-cmyk-fogra.tiff'), "./tmp/thumb")
    assert_true File.exist?(out)
  end
end
