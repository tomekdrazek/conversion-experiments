# @author Tomasz Drazek

# require 'mini_magick'
require 'securerandom' # rendom guid generator
require 'tmpdir'

module SPV
  module Convert
    # Basic process channels and their names:
    CHANNELS = { cyan: 'C', magenta: 'M', yellow: 'Y', black: 'K' }
    # Base resolution for output rendering - the highest bitmap resolution the utility will create (epxressed in DPI)
    BASE_RESOLUTION = 300 # dpi
    # Rendinering resolution is a resolution used during PDF to raster image conversion
    RENDER_RESOLUTION = BASE_RESOLUTION * 2
    # Default output JPEG compression quality (1-100)
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

public
    module_function
    @src = nil
    @report = []
    @config = {}
    @app = "sample"



    # Opens the source document, verfifies its validity, performs appropriate preflight check
    def open(src)

    end

    # Adds selection of the current source document to the cache
    # This method verifies documents, that has been already added to the cache
    # Schedule pages
    # @param sel [String] - expression with a string selection

    def add_pages(sel, ids = nil)

    end

    # Convert of the opened source document,
    def convert

    end


    def schedule
    end

private

    # Gets basic information about source PDF document, such as page count and their geometry.
    # @param src [String] a path to the source PDF file (local file system) to be checked.
    # @return [Array<Object>] returns array of objects with properties of each page: page boxes
    def _check_pdf(src)
      lines = `mutool pages "#{src}"`.split("\n")
      out, cur = [], {}
      lines.each do |l|
        tag, attrs = (/\s*<(\w*)\s(.*)\/?>/.match(l)||[])[1,2]
        if tag
          attr = Hash[attrs.scan(/(\w+)="([\w.]+)"/)] if (attrs)
          if tag=="page"
            out << cur unless cur.empty?
            cur = { 'src' => { 'input' => src, 'page' => attr["pagenum"].to_i, 'type'=>'pdf' }, 'geometry'=>{}}
          else
            attr["w"] = (attr["r"].to_f - attr["l"].to_f).abs
            attr["h"] = (attr["b"].to_f - attr["t"].to_f).abs
            ["w","h","l","t","b","r"].each { |k| attr[k]=attr[k].to_f; attr["#{k}px"]=(attr[k].to_f*BASE_RESOLUTION/72).round;  }
            cur['geometry'][tag.downcase] = attr
          end
        else
          out << cur unless cur.empty?; cur = {}
        end
      end
      out
    end

    # Gets basic information about source bitmap and its geometry
    # @todo Not implemented yet.
    # @param src [String] a path to the source bitmap file (local file system) to be checked.
    # @return [Array<Object>] returns an array of objects with properties of the bitmap page. As bitmaps are always single pages the array will only have one entry.
    def _check_bmp(src)
      d = `gm identify -format "%m,%r,%w,%h,%x,%y,%U,%q" "#{src}"`.to_s.split(',')
      if d && d.count >0
        out, cur, mediabox = [], {}, {}
        resolution = d[4].to_i || 300
        mediabox['tpx'] = mediabox['lpx'] = 0
        mediabox['rpx'] = mediabox['wpx'] = d[2].to_i
        mediabox['bpx'] = mediabox['hpx'] = d[3].to_i
        ["w","h","l","t","b","r"].each { |k| mediabox[k]=mediabox["#{k}px"].to_f*72/resolution; }
        cur = { 'src' => { 'input' => src, 'page' => 1, 'type'=> d[0].to_s, 'color'=> d[1].to_s }, 'geometry'=>{ 'mediabox' => mediabox } }

        out << cur
      end
      out
    end

    # Generate random id based on page_no
    # @return [String] a random seqence of charachters, base 64 to be used as idnetification of newly added page.
    def _generate_id(page_no)
      SecureRandom.urlsafe_base64
    end

    # Applies sel expression on array of pages (taken out of preflight). If ids are delivered, then assigns ids to selection, otherwise generate random id
    # @param src [Arra<Object>] array of page objects (usually result of the preflight)
    # @param sel [String] expression of the page selection
    # @param ids [Array<String>] array of string with ids to be assigned to, if not specified, they will be generated.
    # @return [Array<Object>] filtered array of objects with a page selection, that can be used by conversion engine.
    def _apply_sel(src, sel, ids = nil)
      s = _get_page_sel(sel, src.count)
      out = s.map { |k| src[k-1] }
      ids.each_with_index do |k,i|
        out[i]['id'] = k if out[i]
      end if ids.is_a?(Array)
      i = 1
      out.map! { |k| i+=1; k['id'] = _generate_id(i) unless k['id'] ; k }
      out
    end

    # Converts page selection described by string (str) into an array of page selection
    # @param str [String] an expression that defines a page selection, in a following pattern: `1,2,5~6,-2,-1`, where negative numbers are understood as the n-th page from the end, and tilda `~` separator defines the range - a page seqence.
    # @param page_count [Number] tells the method how many pages are in the sources document to calucate negative numbers correct.
    # @return [Array] returns array of integers (positive, 1-index) of pages in the selection expression.
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

    # Converts the source page delivered as a bitmap (JPG, TIFF)
    # It performs color managment, if required (assumption: the output should be cmyk)
    # Than extracts each channel out of CMYK version of the page.
    # @param src  [String] source pdf file (always pdf or ps)
    # @param dst  [String] output folder to keep temporary channel separations
    # @return [Hash] map of separation name to channel file name, can be used later by #_merge_channels
    def _convert_bmp_page(src, dst, params={})
      # @todo Perform ICC color conversion first:
      # Extract CMYK channels out of the bitmap delivered.
      out = {}
      FileUtils.mkdir_p(dst) # Ensure we have this folder!
      CHANNELS.keys.each do |k|
        basename = Dir::Tmpname.make_tmpname k.to_s, "tmp"
        out[k] = _extract_channel(k,src,File.join(dst, [basename, k.to_s].join))
      end
      out
    end

    # Converts source cmyk tiff into separate channels, and recompose them into RGB buffers:
    # src - full path to source image file
    # dst - a path to the output folder where files will be located
    def _extract_channel(chan, src, dst)
      out = "#{dst}.tif"
      `gm convert "#{src}" -channel #{chan.to_s} -negate +profile "*" -quality 100% -compress None "#{out}"`
      out
    end

    # Recomposes channels into seqence of RGB bitmaps with particular
    # This method first attempts to collect CMY into first bitmap, than K and spot colors in next channels in sequence
    # @param chans [Hash] a separation to file path map
    # @return [Array<Hash>] returns a list of output cache recomposed
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
