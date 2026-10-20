#!/usr/bin/env bash

# create a new staging release 
gh workflow run -R commitchange/deploy-houdini create-release.yml
