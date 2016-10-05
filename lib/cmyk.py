# To use it you need to install:
#  sudo pip install Pillow
# Which is a PIL library replacement
#
# Usage: cmyk.py <Q> [output] [width]
#
#    <Q>      samples/channel resolution: 2 - 256
#    [output] output file path (*jpg / *.tif), default: cmyk-Q.tif
#    [width]  output bitmap widht in pixels, default: smart square ;-)
#
# samples:
#       cmyk.py 64
#       cmyk.py 4  cmyk-4.jpg
#       cmyk.py 32 all32.tif
#

import sys, math, time, subprocess
from PIL import Image

t0 = time.time()

if len(sys.argv) < 2:
    q = 32
else:
    q = int(sys.argv[1])
    if q < 2:
        print "Warning: Min Q is 2 (updated)"
        q = 2
    elif q > 256:
        print "Warning: Max Q is 256 (updated)"
if len(sys.argv) < 3:
    output = "cmyk-%d.tif" % q
else:
    output = sys.argv[2]

# calculate sample coordinates
r = range(0, 256, 256 / q)
if r[-1] != 255:
    r += [255]
q = len(r)

# Set image size
size = q ** 4

if len(sys.argv) < 4:
    w = int(math.ceil(math.sqrt(size)))
else:
    w = int(sys.argv[3])

if (size < w):
    h = 1
    w = size
else:
    h = size // w
    if (size % w) != 0:
        h += 1

print "Generating CMYK table (%d samples/channel, %d total -> %dx%d image) into  '%s' ..." % (q, size, w, h, output)

# Generate image
image = Image.new("CMYK", (w, h), (0, 0, 0, 0))
#image.format = "CMYK"
i = j = 0
for k in r:
    for y in r:
        for m in r:
            for c in r:
                image.putpixel((i, j), (c, m, y, k))
                i += 1
                if i == w:
                    i = 0
                    j += 1;

image.save(output, quality=100, optimize=False)

# Done
print "Done in %.3f s" % (time.time() - t0)
