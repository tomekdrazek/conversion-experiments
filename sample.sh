#!/bin/bash

bundle exec bin/spv-cli intent -s fogra27 http://nullcake.com/test/icc/CMYK/CoatedFOGRA27.icc
sleep 1
bundle exec bin/spv-cli intent -s fogra39 http://nullcake.com/test/icc/CMYK/CoatedFOGRA39.icc
sleep 1
bundle exec bin/spv-cli display -s adobe http://nullcake.com/test/icc/RGB/AdobeRGB1998.icc
sleep 1
bundle exec bin/spv-cli display -s apple http://nullcake.com/test/icc/RGB/AppleRGB.icc
sleep 1
bundle exec bin/spv-cli intent -s uswebcoated http://nullcake.com/test/icc/CMYK/USWebCoatedSWOP.icc
sleep 1


bundle exec bin/spv-cli add http://nullcake.com/test/page.pdf
