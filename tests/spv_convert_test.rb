
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

  def test_pdf_conversion
    page_11 = fixture_path("Olivia-2012-07-011.pdf")
    _lorem = fixture_path("Lorem-ipsum.pdf")
    _page = fixture_path("page.pdf")
    # assert_true File.exists?(page_11)
    # _convert_page(page_11, "./tmp/test/olivia-2012-07-011.tif", 1, {
    #   "-sOutputICCProfile": fixture_path("ISOcoated_v2_eci.icc") } )
    # _convert_page(lorem, "./tmp/test/lorem-2.tif", 2, {
      # "-sOutputICCProfile": fixture_path("ISOcoated_v2_eci.icc") } )
    # _convert_page(lorem, "./tmp/test/lorem-no-cms.tif", 2)

    out =  _convert_pdf_page("src/adv_TUI.pdf", "./tmp/test/tui.tif", 1)
    # cmyk = out.select{|k,v| [:cyan,:magenta,:yellow,:black].include?(k) }
    cmyk = SPV::Convert::CHANNELS.keys.map { |k| out[k] }
    puts cmyk

    _merge_channels(cmyk, "./tmp/test/tui_ad")

    # _convert_page("./tests/fixtures/Olivia-2012-07-011.pdf", "./tmp/test/ol-01.tif", 1)
    # _convert_page(page, "./tmp/test/page-no-cms.tif", 1)
    # _convert_page(page, "./tmp/test/page.tif", 1, {
    #   "-sDefaultCMYKProfile": fixture_path("ISOcoated_v2_eci.icc"),
    #   "-sOutputICCProfile": fixture_path("ISOcoated_v2_eci.icc")
    #   } )
  end
end
