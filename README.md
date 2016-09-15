## Color probes

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
