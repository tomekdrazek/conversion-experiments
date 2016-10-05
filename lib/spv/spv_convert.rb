require 'mini_magick'
require 'securerandom' # rendom guid generator

module SPV
  module Convert
    CONVERT_CMD = 'convert' # ImageMagic conversion
    CHANNELS = { cyan: 'C', magenta: 'M', yellow: 'Y', black: 'K' }
    BASE_RESOLUTION = 300 # dpi
    RENDER_RESOLUTION = BASE_RESOLUTION * 2

    # Ghostscript defult settings:
    GS_DEFAULTS = {
      "-dBATCH": true, # do not use batch script
      "-dNOPAUSE": true,
      "-sDEVICE": "tiffsep",
      "-q": true,
      "-dRenderIntent": 3,
      "-dSimulateOverprint": "true",
      "-dBlackPtComp": 1,
      "-dKPreserve": 2,
      "-r": RENDER_RESOLUTION,
      "-dDeviceGrayToK": "true",
      "-dTextAlphaBits": 4,
      "-dGraphicsAlphaBits": 4,
      # "-dOverrideICC": true,
      # "-dUsePDFX3Profile": 1,
      # "-dUseFastColor": "true",
    }

    module_function

    # opens and
    def open(src)

    end

    def check

    end


    def extract

    end

    # Extract object that can be converted to JSON with output params
    def report

    end

    def _preflight_pdf(src)
      out = `mutool pages "#{src}"`
      out
    end

    # Gets a temporory
    def _tmp(name)

    end

    # Converts the source page of the src document into composite cmyk tiff file
    # @param src  [String] source pdf file (always pdf or ps)
    # @param dst  [String] output folder to keep temporary channel separations
    # @param page [Number]
    # @return [Hash] map of separation name to channel file name, can be used later by #_merge_channels
    # For example { cyan: 'image.c.tif', magenta: 'image.m.tif'}
    def _convert_pdf_page(src, dst, page, params={})
      gs_params = GS_DEFAULTS.merge(params)
      FileUtils.mkdir_p(dst) # Ensure we have this folder!
      basename = Dir::Tmpname.make_tmpname "gs", "tmp"
      hi_res_tif = File.join(dst, [ basename, ".tif" ].join )
      # Somehow gs does not regognize correct -sPageList parameter
      gs_params['-dFirstPage'] = page
      gs_params['-dLastPage'] = page
      gs_params['-sOutputFile'] = hi_res_tif
      puts hi_res_tif
      s_params = gs_params.map {|k,v| !!v==v ? k.to_s : "#{k.to_s}#{"sd".include?(k.to_s[1]) ? '=' : ''}#{v.to_s}" }.join(' ')
      puts "gs #{s_params} \"#{src}\""
      puts `gs #{s_params} "#{src}"`
      channels = Dir.glob(File.join(dst, [ basename, "(*).tif" ].join ))
      channels.map { |s| [ s.gsub(/.*\((.*)\)\.tif/, "\\1").downcase.to_sym, s ] }.to_h
      # mutool draw -r 300 -D -A 1 -c cmyk -o out.pam src/Bravo-2012-13.pdf 1 && gm convert out.pam out.tif && open out.tif
    end

    # Converts source cmyk tiff into separate channels, and recompose them into RGB buffers:
    # src - full path to source image file
    # dst - a path to the output folder where files will be located
    def _extract_channel(chan, src, dst)
      out = "#{dst}/#{chan.to_s[0]}.tif"
      `gm convert "#{src}" -channel #{chan.to_s} -negate +profile "*" -quality 100% -compress None "#{out}"`
      # `convert "#{src}"[0] -channel #{chan.to_s} -strip -negate -separate -set colorspace gray "#{out}"`
      # `convert "#{src}"[0] -fx #{CHANNELS[chan]} -strip -negate -set colorspace gray "#{out}"`
      out
    end

    # Recomposes channels into seqence of RGB bitmaps with particular
    # @param chans [Hash] a separation to file path map

    def _merge_channels(chans, dst)
      # check if chans.count==3
      out = "#{dst}/#{chans.map{|c| File.basename(c)[0]}.join}.tif"
      tmp = "#{dst}/#{chans.map{|c| File.basename(c)[0]}.join}-tmp.tif"
      `gm composite -compose CopyGreen "#{chans[1]}" "#{chans[0]}" -quality 100% -compress None "#{tmp}"`
      `gm composite -compose CopyBlue "#{chans[2]}" "#{tmp}" -quality 100% -compress None "#{out}" && rm "#{tmp}"`
      # `convert #{chans.map{|c| '"'+c+'"'}.join(" ") } -channel RGB -combine "#{out}"`
      out
    end

    def cmyk_to_cache(src, dst)
      FileUtils.mkdir_p(dst)
      c = _extract_channel(:cyan,src,dst)
      m = _extract_channel(:magenta,src,dst)
      y = _extract_channel(:yellow,src,dst)
      _k = _extract_channel(:black,src,dst)
      _merge_channels([c,m,y],dst)

      Dir.mktmpdir do |tmp_dir|

      end

    end

  end
end
