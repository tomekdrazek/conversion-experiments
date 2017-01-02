#!/bin/bash


# Samples should work when local service is launched, to do so use rake command:
rake spv:start

# COMMAND LINE INTERFACE:

# Let's assume we're working with the default application sample.json
bundle exec bin/spv-cli -a sample intent -s iso_coated test/fixtures/ISOcoated_v2_eci.icc
bundle exec bin/spv-cli -a sample display -s wide_gamout test/fixtures/WideGamutRGB.icc

# Use the command below to list intents and displays:
bundle exec bin/spv-cli -a sample intent -l
bundle exec bin/spv-cli -a sample display -l

# Sample usage using a command line, with remote download:
bundle exec bin/spv-cli -a remote intent -s fogra27 http://nullcake.com/test/icc/CMYK/CoatedFOGRA27.icc
bundle exec bin/spv-cli -a remote intent -s fogra39 http://nullcake.com/test/icc/CMYK/CoatedFOGRA39.icc
bundle exec bin/spv-cli -a remote intent -s uswebcoated http://nullcake.com/test/icc/CMYK/USWebCoatedSWOP.icc
bundle exec bin/spv-cli -a remote display -s adobe http://nullcake.com/test/icc/RGB/AdobeRGB1998.icc
bundle exec bin/spv-cli -a remote display -s apple http://nullcake.com/test/icc/RGB/AppleRGB.icc

# Use the command below to list intents and displays:
bundle exec bin/spv-cli -a remote intent -l
bundle exec bin/spv-cli -a remote display -l

# Remove of the intent / display
bundle exec bin/spv-cli -a remote display -d apple
bundle exec bin/spv-cli -a remote intent -d fogra27

# Manipulating on the pages (Remote):
bundle exec bin/spv-cli -a remote add -i test-page http://nullcake.com/test/page.pdf
bundle exec bin/spv-cli -a remote add -i l1,l2,l3,l4,l5,l6,l7,l8 http://nullcake.com/test/Lorem-ipsum.pdf
bundle exec bin/spv-cli -a remote get -i test-page
bundle exec bin/spv-cli -a remote list

# REST

export APISRV="localhost:8080"
export APIKEY="-u sample:ii20319hkjasoudoi2iupi1902u4nvbjtoo"

## Should display 'Helo world'
curl -X GET http://$APISRV/test -s $APIKEY

## List all displays
curl -X GET http://$APISRV/displays -s $APIKEY | json_pp

## Get particul display
curl -X GET http://$APISRV/display/wide_gamout $APIKEY | json_pp

## Set display with upload
curl -X PUT http://$APISRV/display/wide_gamout_2 $APIKEY -H "Content-Type: application/octet-stream"  -d @test/fixtures/WideGamutRGB.icc

## Delete intent
curl -X DELETE http://$APISRV/display/wide_gamout_2 $APIKEY | json_pp

## List all intents
curl -X GET http://$APISRV/intents $APIKEY | json_pp

## Get particular intent
curl -X GET http://$APISRV/intent/iso-coated $APIKEY | json_pp

## Set intent with upload
curl -X PUT http://$APISRV/intent/iso-coated_2 $APIKEY -H "Content-Type: application/octet-stream" -d @test/fixtures/ISOcoated_v2_eci.icc | json_pp

## Delete intent
curl -X DELETE http://$APISRV/intent/iso-coated_2 $APIKEY | json_pp

## Put alfa-pdf (body)
curl -X PUT http://$APISRV/page/alfa-pdf $APIKEY -H "Content-Type: application/pdf" --data-binary @test/fixtures/colors-spot.pdf

## Get alfa-pdf
curl -X GET http://$APISRV/page/alfa-pdf $APIKEY | json_pp

## Delete alfa-pdf
curl -X DELETE http://$APISRV/page/alfa-pdf $APIKEY | json_pp

## Put alfa-bmp (body)
curl -X PUT http://$APISRV/page/alfa-bmp -H "Content-Type: image/jpeg" -d @test/fixtures/colors-cmyk-fogra.tiff

## Get alfa-bmp
curl -X GET http://$APISRV/page/alfa-bmp $APIKEY

## Delete alfa-bmp
curl -X DELETE http://$APISRV/page/alfa-bmp?sel=1 $APIKEY

## Put beta-pdf (single file delivered as a multipart)
curl -X PUT $APIKEY http://$APISRV/page/beta?sel=1,2\&id=a1,a2 -H "Content-Type: multipart/form-data; charset=utf8; boundary=__X_PAW_BOUNDARY__"  -F "file1=@test/fixtures/Lorem-ipsum.pdf"

## Get beta-pdf
curl -X GET $APIKEY http://$APISRV/page/beta | json_pp

## Delete beta-pdf
curl -X DELETE http://$APISRV/page/beta $APIKEY

## Put gamma-pdf (src ref)
curl -X PUT $APIKEY http://$APISRV/page/gamma-pdf?sel=1\&src=http:%2F%2Fnullcake.com%2Ftest%2Fpage.pdf

## List all pages
curl -X GET http://$APISRV/pages?sel=1 $APIKEY
