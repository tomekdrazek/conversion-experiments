# spv-cli 

spv-cli provides:

* Basic PDF and raster image (tif, jpg) conversion routines to populate cache for soft proofing viewer (SPV) with a bunch of test, based on open source utilties.
* A command line tool to control cache creation (`spv-cli`)

## Prerequisites

You need to install following libraries and utilities before proceeding:

* Ghostscript, which provides `gs` utility, used to render pages out of PDF files.
* mutool `mutool` utility which makes quick PDF preflight and renders thumbnail of PDF files very fast.
* Graphics Magic (`gm` utility) used for image conversion. This is replecement of ImageMagic which is slow and consumes a lot of memory.

To install them on macOS:
* Install mac ports or homebrew
* With macports perform:
```
sudo port install mupdf graphicsmagick lcms ghostscript
```

Used libraries and GEMS:
* The utility is written in `ruby`, and requires version `2.3.1`. You can install it using `rvm` and create a separate gemset for it to use local bundler repository. Bundler will install required gems.  
* https://github.com/commander-rb/commander - a powerful tool for command line interpreter


## Processing and conversion

The output is generated in folder `public` with following naming pattern:

### Pages cache

Page cache is organized in the folder structure. The top-most level structure is responsible to keep the application namespace, and each page generated for the particular application is located underneath. 

* The page cache description in JSON format: `public/#{app-namespace}/#{page-id}.json`. The file contains description of each page version delivered to the system. 
* ​

Is a page description JSON that points to all versions of the page and sources, describes page geometry etc.

`public/#{app-namespace}/#{page-id}/#{version}.{unique-seq}.jpg`
CMY channels as RGB bitmap (cyan is mapped to red, etc)

`public/#{app-namespace}/#{page-id}/#{version}.k.jpg`
Black channel as a grayscale image.

`public/#{app-namespace}/#{page-id}/#{version}.Pantone CV-231.jpg` additional color channels are rendered their names

`public/#{app-namespace}/#{page-id}/#{version}.thb.jpg`Thumbnail

### Output intents

The output intents are collected similarly under this path:

`public/icc/#{app-namespace}/#{intent-id}.icc`

Where:
* `intent-id` is a common name for the application output intent color space.



## Color probes and calibration

Create color probes with python script:

```
python cmyk.py 64
```

Concert CMYK to RGB using CMS (on Mac):

```
sips --matchTo './profiles/AdobeRGB1998.icc' cmyk-64.tif --out rgb-64.tif
```

Convert RGB to reference JPG:

```
convert rgb-64.tif public/cmyk-64.jpg
```

## Remarks

One important remark, the HAML compiler within nodejs, works little different that the one we know from Ruby. The major difference is the way how hashes (dictionaries) are written, instead of `:a=>'value'` use `a: 'value'` - the notation known from json.

Copyright, the images used in the experiement are sourced form National Geographic Traveller 2015 Issues 1,2,3,4 of 2015.


For color conversion purposes it's nice to use:

http://www.littlecms.com/1/newutils.htm#icctrans


For example:
```
python cmyk.py 64
tifficc -i "profiles/ISOcoated_v2_eci.icc" -o "profiles/AdobeRGB1998.icc" -t 3 cmyk-64.tif iso-argb-64-abs.tif
convert iso-argb-64-abs.tif public/cmyk-64.jpg
```

Will create a 64 sample base, than convert it using absolute `-t 3` conversion between ISO Coated and Adobe RGB and convert to jpeg samples.

## Useful Tricks

If you have multiple page PDF, you can use following code to extract yeach page to separate PDF:

```
144.times { |k| `mutool merge -o src/Olivia-2012-07-#{"%03d"%k}.pdf src/Olivia-2012-07.pdf #{k}`}
```
