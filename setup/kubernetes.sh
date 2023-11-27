# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#expose port 8080 for ArgoCD UI and 9999 for Netflix-app
k3d cluster create -p 8080:80@loadbalancer -p 9999:30007@loadbalancer

# Install Kubectl
sudo apt -y update
sudo apt -y install -y apt-transport-https ca-certificates curl
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt -y update
sudo apt -y install kubectl

# Install HELM
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt -y install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt -y update
sudo apt -y install helm

# Create namespaces
kubectl create namespace argocd
kubectl create namespace netflix
kubectl create namespace prometheus-node-exporter

# Install ArgoCD
kubectl apply -n argocd -f ../ArgoCD/install.yaml

# Wait for ArgoCD to be ready
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=5m
sleep 5

# Apply ingress to get access for ArgoCD UI
kubectl apply -n argocd -f ../ArgoCD/ingress.yaml

# Apply the app to be deployed in ArgoCD
kubectl apply -n argocd -f ../Kubernetes/netflix.application.yaml
sleep 5



i=0
while [ $i -lt 240 ]
do
    echo -n "/"
    sleep 0.008
    i=$((i + 1))
    if [ $i = 60 ] || [ $i = 180 ];then
        echo ""
    fi
    if [ $i = 120 ]; then
        echo ""
        echo "ArgoCD UI"
        echo "Username 🧑‍💻: admin"
        echo -n "Password 🔐: "
        # Password for ArgoCD UI
        kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
        echo ""
        echo "ArgoCD UI 🌐: http://192.168.56.110:8080"
        echo "Schahid APP 🌐: http://192.168.56.110:9090"
    fi
done
echo ""