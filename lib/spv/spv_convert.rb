require 'mini_magick'
require 'securerandom' # rendom guid generator

module SPV
  module Convert
    CONVERT_CMD = 'convert' # ImageMagic conversion
    CHANNELS = { cyan: 'C', magenta: 'M', yellow: 'Y', black: 'K' }
    BASE_RESOLUTION = 300 # dpi
    RENDER_RESOLUTION = BASE_RESOLUTION * 2
    COMPRESSION_QUALITY = 95
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

    def _get_page_sel(str,page_count = 0)
      out=[]
      def _rfind(i,page_count)
        i = i.to_i; i > 0 ? i : page_count + i > 0 ? page_count + i + 1 : 1
      end
      chunks = str.gsub(/\s+/, "").split(",") # remove all white spaces
      chunks.each do |chunk|
        if chunk.include? '~'
          seq = chunk.split('~')
          (_rfind(seq[0],page_count).._rfind(seq[1],page_count)).each { |k| out << k }
        else
          out << _rfind(chunk,page_count)
        end
      end
      out
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
      gs_params['-dFirstPage'] = page # Somehow gs does not regognize correct -sPageList parameter
      gs_params['-dLastPage'] = page
      gs_params['-sOutputFile'] = hi_res_tif
      s_params = gs_params.map {|k,v| !!v==v ? k.to_s : "#{k.to_s}#{"sd".include?(k.to_s[1]) ? '=' : ''}#{v.to_s}" }.join(' ')
      `gs #{s_params} "#{src}" 2>/dev/null`
      channels = Dir.glob(File.join(dst, [ basename, "(*).tif" ].join ))
      channels.map do |s|
        chan_name = s.gsub(/.*\((.*)\)\.tif/, "\\1")
        chan_name = chan_name.downcase.to_sym if CHANNELS.keys.include?(chan_name.downcase.to_sym)
        [ chan_name, s ]
      end.to_h
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

    def _merge_channels(chans, dst, prefix = "")
      # First extract channels to the sequence CMY, K12, 345, etc.
      conv = []
      if chans.is_a?(Hash)
        seq, chn = [], []
        CHANNELS.keys.each do |k|
          chn << k
          seq << chans.delete(k)
          if seq.count > 2
            conv << { channels: chn, srcs: seq }
            chn, seq = [], []
          end
        end
        chans.each do |k,s|
          chn << k
          seq << s
          if seq.count > 2
            conv << { channels: chn, srcs: seq }
            chn, seq = [], []
          end
        end
        conv << { channels: chn, srcs: seq } if seq.count > 0
      end
      seq=0
      FileUtils.mkdir_p(dst)
      conv.each do |v|
        s=v[:srcs]
        basename = Dir::Tmpname.make_tmpname("#{prefix}-", "-%03d" % seq)
        out = File.join(dst, [basename,".jpg"].join)
        Dir.mktmpdir do |tmp_dir|
          tmp1 = File.join(tmp_dir,[basename,".1.tif"].join)
          tmp2 = File.join(tmp_dir,[basename,".2.tif"].join)
          if s[1]
            `gm composite -compose CopyGreen "#{s[1]}" "#{s[0]}" -quality 100% -compress None "#{tmp1}"`
            if s[2]
              `gm composite -compose CopyBlue "#{s[2]}" "#{tmp1}" -quality 100% -compress None "#{tmp2}"`
            else
              tmp2 = tmp1 # do nothing, last channel is missing in the sequence.
            end
          else
            tmp2 = s[0] # this channel is a tmp2 in fact - use grayscale defintion
          end
          `gm convert "#{tmp2}" -resample #{BASE_RESOLUTION}x#{BASE_RESOLUTION} -quality #{COMPRESSION_QUALITY} "#{out}"`
        end
        v[:img] = out
        v.delete(:srcs)
        seq+=1
      end
      conv
      # check if chans.count==3
      # out = "#{dst}/#{chans.map{|c| File.basename(c)[0]}.join}.tif"
      # tmp = "#{dst}/#{chans.map{|c| File.basename(c)[0]}.join}-tmp.tif"
      # `gm composite -compose CopyGreen "#{chans[1]}" "#{chans[0]}" -quality 100% -compress None "#{tmp}"`
      # `gm composite -compose CopyBlue "#{chans[2]}" "#{tmp}" -quality 100% -compress None "#{out}" && rm "#{tmp}"`
      # # `convert #{chans.map{|c| '"'+c+'"'}.join(" ") } -channel RGB -combine "#{out}"`
      # out
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
