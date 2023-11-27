#! /bin/bash

# Install Docker

sudo apt -y update

sudo apt -y install apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt install docker-ce -y

sudo usermod -aG docker $USER 
newgrp docker
sudo chmod 777 /var/run/docker.sock







