require 'mini_magick'
require 'securerandom' # rendom guid generator

module SPV
  module Convert
    CONVERT_CMD = 'convert' # ImageMagic conversion
    CHANNELS = { cyan: 'C', magenta: 'M', yellow: 'Y', black: 'K' }
    BASE_RESOLUTION = 300 # dpi

    # Ghostscript defult settings:
    GS_DEFAULTS = {
      "-dSAFER": true,
      "-dBATCH": true,
      "-dNOPAUSE": true,
      "-sDEVICE": "tiff32nc",
      "-r": BASE_RESOLUTION,
      "-dTextAlphaBits": 4,
      "-dGraphicsAlphaBits": 4
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

    # Converts the source page of the src document into composite cmyk tiff file
    # @param src  [String] source pdf file (always pdf or ps)
    # @param dst  [String] output image file (always CMYK tif)
    # @param page [Number]
    # @return [Boolean] true or false
    def _convert_page(src, dst, page, params={})

      gs_params = GS_DEFAULTS.merge(params)
      gs_params['-dFirstPage'] = page
      gs_params.map
      # gs -sDEVICE=tiff32nc -r300 -sDefaultCMYKProfile=src/icc/ISOcoated_v2_eci.icc -sOutputICCProfile=src/icc/ISOcoated_v2_eci.icc -sOutputFile=foo-%ld.tif -sPageList=1 -dTextAlphaBits=4 -dGraphicsAlphaBits=4 -dNOPAUSE -dBATCH src/Olivia-2012-07.pdf

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
    end

  end
end
