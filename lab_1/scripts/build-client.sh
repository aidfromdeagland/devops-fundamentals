#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
ROOT_DIR=${SCRIPT_DIR%/*}
CLIENT_BUILD_DIR=$ROOT_DIR/dist/static
CLIENT_BUILD_FILE=$ROOT_DIR/dist/client-app.zip
ENV_CONFIGURATION=

if [ -e "$CLIENT_BUILD_FILE" ]; then
  rm "$CLIENT_BUILD_FILE"
  echo "$CLIENT_BUILD_FILE was removed."
fi

read -p "would you like to build using production configuration? (y/n): " isProductionConfig
if [[ $isProductionConfig =~ ^[Yy]$ ]]; then
    ENV_CONFIGURATION=production
fi

npm install
cd "$ROOT_DIR" && ng build --configuration="$ENV_CONFIGURATION" --output-path="$CLIENT_BUILD_DIR"
zip -r "$CLIENT_BUILD_FILE" "$CLIENT_BUILD_DIR"/*

echo "Client app was built with $ENV_CONFIGURATION configuration."
