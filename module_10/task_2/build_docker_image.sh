#!/bin/bash

registryAddress="localhost:5000"
defaultImageTag="image-$(date +'%Y_%m_%d_%H_%M')"

echo -n "enter a tag for the image (default: $defaultImageTag): "
read -r imageTag
imageTag=${imageTag:-$defaultImageTag}

echo -n "enter a tag for the image uploaded to registry (default: $defaultImageTag): "
read -r imageTagForRegistry
imageTagForRegistry=${imageTagForRegistry:-$defaultImageTag}

registryImagePath="$registryAddress/$imageTagForRegistry"

docker build . -t "$imageTag"
docker image tag "$imageTag" "$registryImagePath"
docker push "$registryImagePath"

