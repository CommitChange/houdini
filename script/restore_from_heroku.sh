#!/bin/bash

url=$(heroku pg:backups:url -a commitchange) || exit 1 # we couldn't get the url

curl -fo "${CC_PROD_DUMP_PATH:-db/dumps/$(date +%Y%m%d%H%M%S).dump}" "$url" || exit 1 # curl didn't work

bin/rails dumpcar:restore
