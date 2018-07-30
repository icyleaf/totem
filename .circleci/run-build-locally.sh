#!/usr/bin/env bash

GH_USER=icyleaf
GH_REPO=totem
GH_BRANCH="feature/remote-config"
GH_HASH=fac72c19ee1714df8dd4f9c375d65e27fa53ed69

curl --user ${CIRCLE_TOKEN}: \
     --request POST \
     --form revision=${GH_HASH}\
     --form config=@config.yml \
     --form notify=false \
     https://circleci.com/api/v1.1/project/github/${GH_USER}/${GH_REPO}/tree/${GH_BRANCH}