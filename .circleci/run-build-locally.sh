#!/usr/bin/env bash

GH_USER=icyleaf
GH_REPO=totem
GH_BRANCH="feature/remote-config"
GH_HASH=60ee1c094132f8be93b023c9a2578e045e5e4b99

curl --user ${CIRCLE_TOKEN}: \
     --request POST \
     --form revision=${GH_HASH} \
     --form config=@config.yml \
     --form notify=false \
     https://circleci.com/api/v1.1/project/github/${GH_USER}/${GH_REPO}/tree/${GH_BRANCH}