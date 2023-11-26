#! /bin/bash

# Install SonarQube

docker run -d --name sonarQube -p 9000:9000 sonarqube:lts-community

# Install Trivy

sudo apt -y install wget apt-transport-https gnupg lsb-release
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt -y update
sudo apt -y install trivy


# Install Java
sudo apt -y update
sudo apt -y install fontconfig openjdk-17-jre

# Install Jenkins

sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt -y update
sudo apt -y install jenkins

while true; do
    if systemctl is-active jenkins &> /dev/null; then
        echo "Jenkins is"
        sleep 1
        echo "Password: " && sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        echo "SonarQube User: admin \nSonarQube Pass: admin"
        break
    else
        echo "Jenkins is strating ........."
        sleep 5
    fi
done
