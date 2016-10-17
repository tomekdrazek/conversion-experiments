# spv-cli 

spv-cli provides:

* Basic PDF and raster image (tif, jpg) conversion routines to populate cache for soft proofing viewer (SPV) with a bunch of test, based on open source utilties.
* A command line tool to control cache creation (`spv-cli`)

## Installation

### Prerequisites

You need to install following libraries and utilities before proceeding:

* **Ghostscript**, which provides `gs` utility, used to render pages out of PDF files. Visit developer's website: http://ghostscript.com. 
* **mutool** `mutool` utility which makes quick PDF preflight and renders thumbnail of PDF files very fast. Visit developer's website: http://mupdf.com 
* **Graphics Magic** (`gm` utility) used for image conversion. This is replecement of ImageMagic which is slow and consumes a lot of memory. Visit developer's website: http://www.graphicsmagick.org
* **Little CMS** used internally for color manage tiff files  (`tifficc` utility)  and control reference color probes, that controls browser, client side color conversion process.

The set of libraries and tools used is for experimental purposes only. In the final version of the application, these utilities may be replaced with customized executables based on Vertex Libs.

#### Install on macOS:

* Install **MacPorts** or **Homebrew** to support open source utilities and libraries.
* With **MacPorts** perform:
```shell
sudo port install mupdf graphicsmagick lcms ghostscript
```

#### Install on Linux (Ubuntu)

> ***TODO: Write this section***

### Setup the utility 

When all libraries and required dependencies are installed, you need to prepare bundle with a gemset:

First ensure the bundler is installed for the current gemset (if you are using RVM or any other version manager):

```shell
gem install bundler
```

And than install dependencies:

```
bundle install
```

Used libraries and GEMS:

- The utility is written in `ruby`, and requires version `2.3.1`. You can install it using `rvm` and create a separate gemset for it to use local bundler repository. Bundler will install required gems.  
- The documentation requires `yard` to be installed. 
- https://github.com/commander-rb/commander - a powerful tool for command line interpreter

### Documentation

The source code of the spv-cli is equipped with decent source code documentation that can be easy build on demand using yard, just perform following command:

```
yard
```

And the documentation in viewable HTML format will be created in `doc/index.html`. 

## Processing and conversion

### Configuration 

The configuration files are application dependant. All configuration are kept in `config` folder of the utility.  Configurations are kept in a form of JSON file. Configuration name must match application namespace provided to the utility. 

```json
{
  "namespace": "Automator",
  "pageName": "{randomHex:2}-{randomHex:4}-{randomHex:2}",
  "feedback": [
    {
      "url": "https://app-back-end:8080/updates/{pageId}",
      "method": "post",
    },
    {
      "cmd": "echo 'INSERT INTO page_updates (id) VALUES ({pageId})' | psql db" 
    }
  ],
  "APIKeys": {
    "automator-a-1": "ii20319hkjasoudoi2iupi1902u4nvbjtoo",
    "automator-a-2": "iuiurhfbjhdsfu23hyh8919289yhr98auso",
  }
}
```

The key feature for the utility is convert a source document that can be PDF or bitmap into a cache data for 

* `namespace` is a human readable name of the application namespace (not used so far)
* `pageName` is a way how the page name is generated. The convention is applied to the pages that does have assigned page id via API itself. 
* ​

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

## Code testing

The code test are mostly running via set of tests running

## Remarks


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
