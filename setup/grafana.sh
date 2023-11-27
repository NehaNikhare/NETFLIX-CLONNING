#! /bin/bash

# Install Grafana

sudo apt -y update
sudo apt install -y apt-transport-https software-properties-common

wget -q -O - https://packages.grafana.com/gpg.key | sudo apt-key add -
echo "deb https://packages.grafana.com/oss/deb stable main" | sudo tee -a /etc/apt/sources.list.d/grafana.list

sudo apt -y update
sudo apt -y install grafana

sudo systemctl enable grafana-server
sudo systemctl start grafana-server