#!/bin/bash

SCRIPT_DIR=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
ROOT_DIR=${SCRIPT_DIR%/*}

cd "$ROOT_DIR" || exit

npm install
npm audit
ng lint
ng test --watch=false
ng e2e --configuration=production