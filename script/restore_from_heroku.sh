#!/bin/bash

# whoami returns an error code if not logged in. We then attempt login. If that fails, we exit. If anything succeed, keep going.
heroku whoami || heroku login || exit 1

url=$(heroku pg:backups:url -a commitchange) || exit 1 # we couldn't get the url

curl -fo "${CC_PROD_DUMP_PATH:-db/dumps/$(date +%Y%m%d%H%M%S).dump}" "$url" || exit 1 # curl didn't work

bin/rails dumpcar:restore

bin/rails db:environment:set RAILS_ENV=development 
