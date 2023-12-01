# Netfix Clone (DevSecOps project)
### !!! Netflix-Clone code its not mine !!!

This DevSecOps pipeline orchestrates the end-to-end development, security, and deployment processes for a Netflix clone. It begins by fetching the code from GitHub and rigorously examines its quality through SonarQube analysis and a stringent quality gate check. Security remains paramount, with OWASP and Trivy scans ensuring dependencies and the Docker image are free from vulnerabilities. Post-analysis, the pipeline seamlessly builds, pushes, and deploys the application using Docker, while ArgoCD and K3D handle the continuous deployment and management within a Kubernetes cluster. This comprehensive approach automates and safeguards the entire development lifecycle, ensuring a robust, secure, and efficiently deployed Netflix-like application.

![](https://github.com/chahid001/Netflix-Clone-DevSecOps/blob/main/assets/s.png)
# Deployment

## Step 1: Inistial Setup
### Create EC2 instance or Azure VM
First of all you need to create your EC2 instance (AWS) or your prefered cloud provider, in my case im working with Azure.

#### Create your VM or instance
#### Open inbound ports for :
- Jenkins: 8080
- Netflix-Clone: 8081
- SonarQube: 9000
#### Connect with it using SSH

```bash
ssh -i <pem_file>.pem user@public_ip
```

### Clone the project 
Clone the project to the server

```bash
  git clone https://github.com/chahid001/Netflix-Clone-DevSecOps.git
```

### Install Docker

Access the folder 'setup' to run the script 

```bash
sh docker-install.sh
```

### Create TMDB API 

For the app to run correctly, we need the movie database API, go to the [site](https://www.themoviedb.org/).

- Create an account
- Settings -> API
- Fill out the required information
- Create the API 

### Running Netflix clone

Access 'app' folder and build the Dockerfile

```bash
docker build --build-arg TMDB_V3_API_KEY=<API-KEY> -t netflix-clone .
```

and Run it

```bash
docker run -d -p 8081:80 netflix-clone
```

### Installing SonarQube, Jenkins & Trivy

acces 'setup' folder and run the script

```bash
sh STJ-install.sh
```

#### The script will provide you the credentials for both Jenkins and SonarQube

#### You can acces :

- Netflix-Clone: <public_ip>:8081
- Jenkins: <public_ip>:8080
- SonarQube: <public_ip>:9000

#### Also you need to add the following plugins to Jenkins:

- NodeJS
- Eclipse Temurin installer (for installing JDK)
- SonarQube scanner
- Workspace Cleanup
- OWASP scanner
- Docker

#### Then after that you can add JDK and NodeJS in Tools:

- Manage Jenkins -> tools -> add JDK & add NodeJS, SonarQube scanner, OWASP and Docker

#### And configure SonarQube credentials

- Go to SonarQube >> Administration -> Security -> Users -> Update token (Administrator) -> Generate new token -> Copy the token

- Go to Jenkins >> Manage Jenkins -> Credentials -> global -> add new credentials -> Kind (special text) -> past the SQ token and add an ID -> Create 

#### Configure SonarQube server in Jenkins

- Jenkins >> Manage Jenkins -> Sytstem -> SonarQube server (add SonarQube) -> enter a Name, IP addr, credentials that you created -> hit apply

#### Create a project in SonarQube

- SonarQube >> Projects -> Manually -> Locally -> Generate -> Continue -> Select other then Linux

- Copy the command, you will need it for the SonarQube Analysis stage in Jenkins pipeline

#### ! You can now stop and remove the netflix container !
## Step 2: CI/CD pipeline

#### Add Credentials

Just as before you need to add some credentials so the pipeline can run smoothly

- TMDB API as Special text
- Docker credentials as Username & Password
- SonarQube Login and IP addr that are in the command you copied before in 'Create Project SQ' stage as Special texts
- Github Credentials fot the repo where you put your manifetst files

So basically when we push the Image to the DockerHUB, the pipeline going to change the deployment manifest file to the right build number of the image, so can ArgoCD sync and pull the new version of the image and deploy it.

#### !! Remember to modify the names in the Jenkinsfile so they can be appropriate with the credentials and ENV !!

Access the Jenkinsfile in the repo and copy it, then :
- Jenkins >> new item -> pipeline -> apply

if you encounter some permission problemes in the Docker build stage:

```bash
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

## Step 3: Monitoring

### Create another server using EC2 or Azure VM

#### Open inbound-ports for :

- Node-exporter: 9100
- Prometheus: 9090
- Grafana: 3000

### Install Prometheus

Like Docker and the others, run the prometheus script to install it

```bash
sh setup/prometheus.sh
```
Now, you need to create a system service file for Prometheus. Create and open a prometheus.service file with the Nano text editor using:

```bash
sudo nano /etc/systemd/system/prometheus.service
```
and add this, save and exit:

```bash
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=prometheus
Group=prometheus
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/prometheus \
  --config.file=/etc/prometheus/prometheus.yml \
  --storage.tsdb.path=/data \
  --web.console.templates=/etc/prometheus/consoles \
  --web.console.libraries=/etc/prometheus/console_libraries \
  --web.listen-address=0.0.0.0:9090 \
  --web.enable-lifecycle

[Install]
WantedBy=multi-user.target
```

#### Enable and start Prometheus

```bash
sudo systemctl enable prometheus
sudo systemctl start prometheus
```

### Install Node-exporter

Like above, run the node-exporter script to install it

```bash
sh setup/node-exporter.sh
```
Now, you need to create a system service file for node-exporter. Create and open a node_exporter.service file with the Nano text editor using:

```bash
sudo nano /etc/systemd/system/node_exporter.service
```
and add this, save and exit:

```bash
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

StartLimitIntervalSec=500
StartLimitBurst=5

[Service]
User=node_exporter
Group=node_exporter
Type=simple
Restart=on-failure
RestartSec=5s
ExecStart=/usr/local/bin/node_exporter --collector.logind

[Install]
WantedBy=multi-user.target
```

Then enable and start the service, like you did with Prometheus.

### Integrate Node-exporter & Jenkins with Prometheus

#### 1- Add Prometheus add-ons to Jenkins

After adding the plugin you can find the metrics at 
#### http://<Jenkins-IP>:8000/prometheus
#### 2- Modify Prometheus yml file

```bash
- job_name: '<Your job name>'
  metric_path: '<Your job path>'
  static_configs:
    - targets: ['<IP ADDRESS>']
```
So we gonna integrate both Node_exporter & Jenkins

```bash
sudo nano /etc/prometheus/prometheus.yml
```
```bash
scrape_configs:
  - job_name: "node_exporter"
    static_configs:
      - targets: ["localhost:9100"]

  - job_name: "jenkins"
    metrics_path: "/prometheus"
    static_configs:
      - targets:["<your-jenkins-ip>:8080"]
```
To verify everything is good, run 

```bash
promtool check config /etc/prometheus/prometheus.yml
```

If it shown SUCCESS, reload Prometheus configuration 

```bash
curl -X POST http://localhost:9090/-/reload
```

### Install Grafana

Like above, run the Grafana script to install it

```bash
sh setup/grafana.sh
```

#### Add Prometheus

You can add Prometheus as a Data source, just go to Grafana GUI , HTTP://<IP_ADDR>:3000

- Add Data source
- Select Prometheus >> Add Connection >> http://localhost:9090
- Click save

- Return to Home >> Add new Dashboard -> Import a Dashboard
- Go to [Graphana Labs](https://grafana.com/grafana/dashboards/1860-node-exporter-full/) and copy the ID
- Return to Grafana and load the ID


#### Add Jenkins

- Same thing as Promethus
- Jenkins dash -> [Grafana Labs](https://grafana.com/grafana/dashboards/9964-jenkins-performance-and-health-overview/)


## Step 3: Email add-ons

### Get app Password

#### Go to Manage my google account

- In the search bar, type -app passwords-
- Create a new app
- Copy the code

### Setup Jenkins with Email notifications

- Jenkins >> Manage Jenkins -> System -> Email notifications
- Add the following credentials:

    - SMTP Server: smtp.gmail.com
    - user email: <Your-email>

- In the Advance section, add:

    - User email: <Your-email>
    - Password: <the code you copied>

- Check Use SSL 
- SMTP port: 465

### Extended E-mail Notification

- Jenkins >> Manage Jenkins -> System -> Extended E-mail Notification
- Add the following credentials:

    - SMTP Server: smtp.gmail.com
    - SMTP Port: 465

- In the Advance section, add the credentials you already created.
- Check Use SSL 
- Choose Default content type as HTML
- Configure the triguer as you like

## Step 4: Kubernetes 

There is 2 methods, the first one is creating a Kubernetes cluster using a cloud provider service (EKS or AKS), the second one is to create a third VM and install it manualy.

Im gonna stick with the second method, and im gonna install K3D because its ligheweight and easy to install, so like the others just use the script provided in the 'setup' folder.

```bash
sh setup/docker-install.sh
sh setup/kubernetes.sh
```

The script will :

- Install K3D
- Install Kubectl
- Create K3S cluster and port mapping for both Netflix-clone and ArgoCD
- Create Namespaces for ArgoCD and Netflix-clone
- Install ArgoCD
- Deploy Netflix-clone


