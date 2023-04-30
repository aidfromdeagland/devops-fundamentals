#!/bin/bash

SERVER_HOST_DIR=$(pwd)/nestjs-rest-api
CLIENT_HOST_DIR=$(pwd)/shop-angular-cloudfront

SERVER_REMOTE_DIR=/var/app/backend_nestjs
CLIENT_REMOTE_DIR=/var/www/frontend-angular

check_remote_dir_exists() {
  echo "Check if remote directories exist"

  if ssh ubuntu-sshuser "[ ! -d $1 ]"; then
    echo "Creating: $1"
	ssh -t ubuntu-sshuser "sudo bash -c 'mkdir -p $1 && chown -R sshuser: $1'"
  else
    echo "Clearing: $1"
    ssh ubuntu-sshuser "sudo -S rm -r $1/*"
  fi
}

check_remote_dir_exists $SERVER_REMOTE_DIR
check_remote_dir_exists $CLIENT_REMOTE_DIR

echo "---> Building and copying server files - START <---"
echo "$SERVER_HOST_DIR"
cd "$SERVER_HOST_DIR" && npm run build
scp -Cr dist/ package.json .env ubuntu-sshuser:$SERVER_REMOTE_DIR
echo "---> Building and transfering server - COMPLETE <---"

echo "---> Building and transfering client files, cert and ngingx config - START <---"
echo "$CLIENT_HOST_DIR"
cd "$CLIENT_HOST_DIR" && npm run build && cd ../
scp -Cr "$CLIENT_HOST_DIR"/dist/ "$CLIENT_HOST_DIR"/nginx_configuration.conf ubuntu-sshuser:"$CLIENT_REMOTE_DIR"
echo "---> Building and transfering - COMPLETE <---"

echo "---> Setup server - START <---"
ssh ubuntu-sshuser "cd $SERVER_REMOTE_DIR && npm i && npx pm2 stop nestjs-api && npx pm2 delete nestjs-api"
ssh ubuntu-sshuser "cd $SERVER_REMOTE_DIR && npm run start:pm2"
echo "---> Setup server - FINISH <---"
