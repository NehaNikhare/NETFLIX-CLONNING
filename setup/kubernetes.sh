#! /bin/bash

# Install Kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl

# Install k3d
curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash

#expose port 8080 for ArgoCD UI and 9999 for Netflix-app
k3d cluster create -p 8080:80@loadbalancer -p 9999:30007@loadbalancer

# Create namespaces
kubectl create namespace argocd
kubectl create namespace netflix

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
    fi
done
echo ""