#! /bin/bash

#install Docker

sudo apt -y update

sudo apt -y install docker.io
sudo snap install docker

sudo usermod -aG docker $USER 
newgrp docker
sudo chmod 777 /var/run/docker.sock







