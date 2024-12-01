#!/bin/bash
set -x

# user home
cd ~

# install docker
sudo apt-get install curl
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update 
sudo apt-get install -y --no-install-recommends build-essential jq awscli python3-boto3 docker-ce docker-ce-cli containerd.io docker-compose-plugin

# user home
sudo usermod -aG docker $USER
