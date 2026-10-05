# Flask Kubernetes & Azure Container Apps CI/CD

A containerized Flask application demonstrating an end-to-end **DevOps and CI/CD workflow** using GitHub, Jenkins, Docker, Kubernetes (Kind), Azure Container Registry (ACR), and Azure Container Apps.

The project starts with a Flask application stored in GitHub and uses Jenkins to automatically test, build, publish, and deploy the application.

---

## CI/CD Architecture

```text
                         GitHub
                           |
                           v
                        Jenkins
                           |
             +-------------+-------------+
             |             |             |
             v             v             v
          Checkout       Tests       Docker Build
                                         |
                                         v
                              +----------+----------+
                              |                     |
                              v                     v
                         Docker Hub                 ACR
                              |                     |
                              v                     v
                       Kind Kubernetes      Azure Container Apps
                              |                     |
                              v                     v
                         Local App            Public HTTPS App
```

### Pipeline Flow

```text
GitHub
  |
  v
Jenkins
  |
  +--> Checkout source code
  |
  +--> Install Python dependencies
  |
  +--> Run pytest
  |
  +--> Build Docker image
  |
  +--> Push image to Docker Hub
  |
  +--> Load image into Kind
  |
  +--> Deploy to Kubernetes
  |
  +--> Verify Kubernetes deployment
  |
  +--> Push image to Azure Container Registry
  |
  +--> Deploy image to Azure Container Apps
  |
  +--> Verify Azure deployment
```

---

# Project Overview

This project demonstrates a complete containerized application deployment workflow.

The project includes:

* Flask application development
* Python dependency management
* Docker containerization
* Local Docker testing
* Kubernetes deployment using Kind
* Kubernetes Deployment
* Kubernetes Service
* Kubernetes ConfigMap
* Kubernetes Secret
* Resource requests and limits
* Readiness probes
* Liveness probes
* Kubernetes Metrics Server
* Horizontal Pod Autoscaling (HPA)
* Docker Hub image publishing
* Azure Container Registry
* Azure Container Apps
* Jenkins CI/CD
* GitHub source-code integration
* Automated Kubernetes deployment
* Automated Azure deployment
* Public HTTPS application hosting

---

# Application

The Flask application provides three endpoints.

## `/`

Displays the Flask application dashboard.

The application receives its environment and message from environment variables.

```text
APP_ENV
APP_MESSAGE
```

Example Kubernetes configuration:

```text
APP_ENV=kubernetes
APP_MESSAGE=Hello from Kubernetes
```

Example Azure configuration:

```text
APP_ENV=azure
APP_MESSAGE=Hello from Azure Container Apps
```

## `/health`

Health-check endpoint used by Kubernetes.

```bash
curl http://localhost:5000/health
```

Expected response:

```text
ok
```

The same endpoint is available on Azure:

```bash
curl https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io/health
```

## `/cpu`

Performs a CPU-intensive calculation.

This endpoint is useful for generating CPU load while testing Kubernetes Horizontal Pod Autoscaling.

---

# Project Structure

```text
flask-k8s/
│
├── app.py
├── requirements.txt
├── Dockerfile
├── Jenkins.Dockerfile
├── Jenkinsfile
├── k8s.yaml
├── README.md
├── .gitignore
│
├── templates/
│   └── index.html
│
├── static/
│   └── style.css
│
└── tests/
    └── test_app.py
```

### Important files

| File                   | Purpose                                                  |
| ---------------------- | -------------------------------------------------------- |
| `app.py`               | Flask application                                        |
| `requirements.txt`     | Python dependencies                                      |
| `Dockerfile`           | Application container image                              |
| `Jenkins.Dockerfile`   | Custom Jenkins image with CI/CD tools                    |
| `Jenkinsfile`          | Jenkins CI/CD pipeline                                   |
| `k8s.yaml`             | Kubernetes resources                                     |
| `templates/index.html` | Flask web dashboard                                      |
| `static/style.css`     | Application styling                                      |
| `tests/test_app.py`    | Automated tests                                          |
| `.gitignore`           | Prevents unwanted files and secrets from being committed |
| `README.md`            | Project documentation                                    |

---

# Prerequisites

The project was developed on Ubuntu 24.04.

Required tools include:

* Python 3
* Docker
* kubectl
* Kind
* Azure CLI
* Git
* Jenkins

Check the installations:

```bash
python3 --version
docker --version
kubectl version --client
kind version
az version
git --version
```

---

# 1. Flask Application

The Flask application is defined in:

```text
app.py
```

Run the application locally:

```bash
python3 app.py
```

The application listens on:

```text
http://localhost:5000
```

Test the application:

```bash
curl http://localhost:5000/
```

Test the health endpoint:

```bash
curl http://localhost:5000/health
```

---

# 2. Automated Tests

The project uses `pytest` for automated testing.

Install dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

Run tests:

```bash
python -m pytest
```

Jenkins automatically performs this test stage before building the Docker image.

---

# 3. Docker

Build the Docker image locally:

```bash
docker build -t flask-app:1.0 .
```

Run the container:

```bash
docker run --rm -p 5000:5000 \
  -e APP_ENV=docker \
  -e APP_MESSAGE="Hello from Docker" \
  flask-app:1.0
```

Test the application:

```bash
curl http://localhost:5000/
```

Health check:

```bash
curl http://localhost:5000/health
```

CPU endpoint:

```bash
curl http://localhost:5000/cpu
```

---

# 4. Create a Kind Kubernetes Cluster

Create the local Kubernetes cluster:

```bash
kind create cluster --name flask-k8s
```

Verify the cluster:

```bash
kubectl cluster-info
kubectl get nodes
```

The Kubernetes context is:

```text
kind-flask-k8s
```

---

# 5. Kubernetes Configuration

The Kubernetes configuration is defined in:

```text
k8s.yaml
```

It contains:

* ConfigMap
* Secret
* Deployment
* Service
* HorizontalPodAutoscaler

Apply the configuration:

```bash
kubectl apply -f k8s.yaml
```

Verify the resources:

```bash
kubectl get all
```

---

# 6. Load the Docker Image into Kind

Kind runs Kubernetes nodes inside Docker.

Load the local Docker image into the cluster:

```bash
kind load docker-image flask-app:1.0 --name flask-k8s
```

Verify the local image:

```bash
docker images | grep flask-app
```

For Jenkins deployments, the pipeline automatically loads the build-number-tagged image into Kind.

---

# 7. Kubernetes ConfigMap

The ConfigMap provides the application environment.

Example:

```text
APP_ENV=kubernetes
```

View the ConfigMap:

```bash
kubectl get configmap flask-config -o yaml
```

---

# 8. Kubernetes Secret

The Kubernetes Secret provides the application message.

Example:

```text
APP_MESSAGE=Hello from Kubernetes
```

View the Secret metadata:

```bash
kubectl get secret flask-secret
```

Do not store real production credentials directly in Git.

The Secret used in this demonstration contains a sample application message rather than a production credential.

---

# 9. Kubernetes Deployment

The Deployment runs two Flask replicas.

Check the Deployment:

```bash
kubectl get deployment
```

Check the Pods:

```bash
kubectl get pods
```

The application container uses:

```text
Container port: 5000
Image pull policy: IfNotPresent
```

The initial local image can be:

```text
flask-app:1.0
```

During CI/CD, Jenkins deploys images using the Jenkins build number.

For example:

```text
flask-app:6
```

This provides a unique image tag for each Jenkins build.

---

# 10. Kubernetes Service

The Kubernetes Service is:

```text
flask-service
```

Check it:

```bash
kubectl get service
```

Because Kind is a local Kubernetes cluster, an external cloud load balancer is not automatically created.

Port-forward the Service:

```bash
kubectl port-forward service/flask-service 8081:80
```

The application can then be accessed at:

```text
http://localhost:8081
```

Test it:

```bash
curl http://localhost:8081/
curl http://localhost:8081/health
curl http://localhost:8081/cpu
```

---

# 11. Resource Requests and Limits

The Flask container uses Kubernetes resource requests and limits.

```yaml
requests:
  cpu: "100m"
  memory: "128Mi"

limits:
  cpu: "500m"
  memory: "256Mi"
```

The requests allow Kubernetes to determine the resources required to schedule the Pod.

The limits prevent a container from consuming unlimited CPU or memory.

Inspect the Deployment:

```bash
kubectl describe deployment flask-app
```

---

# 12. Health Probes

The Flask application exposes:

```text
/health
```

Kubernetes uses this endpoint for:

* Readiness probe
* Liveness probe

Inspect a Pod:

```bash
kubectl describe pod <POD_NAME>
```

### Readiness Probe

The readiness probe determines whether a Pod is ready to receive traffic.

### Liveness Probe

The liveness probe allows Kubernetes to detect an unhealthy container and restart it when necessary.

---

# 13. Metrics Server

The Horizontal Pod Autoscaler requires resource metrics.

Install Metrics Server:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For the Kind environment, configure Metrics Server with:

```text
--kubelet-insecure-tls
--kubelet-preferred-address-types=InternalIP,Hostname
```

The configuration can be applied using:

```bash
kubectl patch deployment metrics-server \
  -n kube-system \
  --type='json' \
  -p='[
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args/-",
      "value": "--kubelet-insecure-tls"
    },
    {
      "op": "add",
      "path": "/spec/template/spec/containers/0/args/-",
      "value": "--kubelet-preferred-address-types=InternalIP,Hostname"
    }
  ]'
```

Restart Metrics Server:

```bash
kubectl rollout restart deployment metrics-server -n kube-system
```

Verify:

```bash
kubectl top nodes
kubectl top pods
```

---

# 14. Horizontal Pod Autoscaler

The application uses a Horizontal Pod Autoscaler.

Configuration:

```text
Minimum replicas: 2
Maximum replicas: 5
CPU target: 50%
```

Check the HPA:

```bash
kubectl get hpa
```

Example:

```text
NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS
flask-hpa   Deployment/flask-app   cpu: 1%/50%   2         5         2
```

---

# 15. Test Kubernetes Autoscaling

The `/cpu` endpoint can be used to generate CPU load.

First make sure the application is accessible through the port-forward:

```bash
kubectl port-forward service/flask-service 8081:80
```

Generate load:

```bash
for i in {1..1000}; do
  curl -s http://localhost:8081/cpu > /dev/null &
done
wait
```

Monitor the HPA:

```bash
kubectl get hpa -w
```

Monitor Pods:

```bash
kubectl get pods -w
```

The number of replicas can increase when CPU usage exceeds the configured target.

---

# 16. Jenkins CI/CD

The project uses Jenkins to automate the complete deployment workflow.

The Jenkins pipeline is defined in:

```text
Jenkinsfile
```

A custom Jenkins image is defined in:

```text
Jenkins.Dockerfile
```

The Jenkins image contains the tools required by the pipeline:

* Python
* pytest
* Docker CLI
* kubectl
* Kind
* Azure CLI

---

# 17. Jenkins Pipeline Stages

The Jenkins pipeline contains the following stages:

```text
Checkout
   |
   v
Test
   |
   v
Build Docker Image
   |
   v
Push to Docker Hub
   |
   v
Load Image into Kind
   |
   v
Deploy to Kubernetes
   |
   v
Verify Kubernetes Deployment
   |
   v
Push to Azure Container Registry
   |
   v
Deploy to Azure Container Apps
   |
   v
Verify Azure Deployment
```

### Checkout

Jenkins checks out the source code from GitHub.

### Test

Jenkins creates a Python virtual environment, installs dependencies, and runs:

```bash
python -m pytest
```

### Build Docker Image

The Docker image is built using the Jenkins build number.

For example:

```text
flask-app:6
```

### Push to Docker Hub

The image is tagged and pushed to:

```text
samkasaju/flask-app
```

using the Jenkins Docker Hub credential.

### Load Image into Kind

Jenkins loads the newly built image into the local Kind cluster:

```bash
kind load docker-image flask-app:<BUILD_NUMBER> --name flask-k8s
```

### Deploy to Kubernetes

Jenkins updates the Kubernetes Deployment:

```bash
kubectl set image deployment/flask-app \
  flask-app=flask-app:<BUILD_NUMBER>
```

Then Jenkins waits for the rollout:

```bash
kubectl rollout status deployment/flask-app
```

### Verify Kubernetes Deployment

Jenkins verifies:

```bash
kubectl get pods
kubectl get deployment flask-app
kubectl get service flask-service
```

### Push to Azure Container Registry

Jenkins authenticates with Azure and pushes the image to:

```text
flaskk8sacr1790962364.azurecr.io/flask-app
```

The same Jenkins build number is used as the image tag.

For example:

```text
flaskk8sacr1790962364.azurecr.io/flask-app:6
```

### Deploy to Azure Container Apps

Jenkins updates the Azure Container App to use the new ACR image.

### Verify Azure Deployment

Jenkins verifies that the Container App is:

```text
Provisioning State: Succeeded
Running Status:     Running
```

---

# 18. Jenkins Credentials

The Jenkins pipeline uses credentials rather than hard-coding secrets.

The configured credentials include:

```text
dockerhub-creds
azure-sp
azure-tenant-id
```

These credentials are referenced by the Jenkinsfile.

Secrets are not stored directly inside the pipeline source code.

### Important

Never commit the following to GitHub:

* Docker Hub passwords or access tokens
* Azure service principal secrets
* Azure credentials
* ACR passwords
* API keys
* SSH private keys
* `.env` files

---

# 19. Docker Hub

The Jenkins pipeline publishes images to Docker Hub.

Repository:

```text
samkasaju/flask-app
```

Images use Jenkins build numbers as tags.

Example:

```text
samkasaju/flask-app:6
```

Using build numbers makes it possible to identify which Jenkins build produced a particular image.

---

# 20. Azure CLI

Login to Azure:

```bash
az login
```

Check the active subscription:

```bash
az account show --output table
```

The project was developed using an Azure for Students subscription.

Set the main variables:

```bash
export RESOURCE_GROUP="flask-k8s-rg"
export LOCATION="centralindia"
export AKS_NAME="flask-k8s-aks"
export ACR_NAME="flaskk8sacr$(date +%s)"
```

Create the resource group:

```bash
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION"
```

---

# 21. Azure Container Registry

The project uses Azure Container Registry to store images used by Azure Container Apps.

The final ACR is:

```text
flaskk8sacr1790962364
```

Login server:

```text
flaskk8sacr1790962364.azurecr.io
```

Create an ACR:

```bash
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic
```

Get the login server:

```bash
export ACR_LOGIN_SERVER=$(az acr show \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query loginServer \
  --output tsv)
```

Login:

```bash
az acr login --name "$ACR_NAME"
```

---

# 22. Azure Container Registry Image

The Jenkins pipeline pushes the Docker image to ACR using the Jenkins build number.

Example:

```text
flaskk8sacr1790962364.azurecr.io/flask-app:6
```

List image tags:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository flask-app \
  --output table
```

---

# 23. Azure Container Apps

Azure Container Apps is the successful cloud deployment platform for this project.

The Container Apps environment is:

```text
flask-k8s-env
```

The Container App is:

```text
flask-app
```

The application runs in:

```text
Central India
```

The Container App configuration includes:

```text
CPU:          0.5
Memory:       1.0Gi
Min replicas: 1
Max replicas: 3
Ingress:      External
Target port:  5000
```

---

# 24. Azure Container Apps Environment

Register the required Azure providers:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
```

Create the Container Apps environment:

```bash
export CONTAINERAPPS_ENVIRONMENT="flask-k8s-env"

az containerapp env create \
  --name "$CONTAINERAPPS_ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"
```

---

# 25. ACR Authentication

The Container App needs permission to pull the private image from ACR.

The deployment used ACR registry credentials.

Enable ACR admin credentials:

```bash
az acr update \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --admin-enabled true
```

Retrieve the credentials:

```bash
export ACR_USERNAME=$(az acr credential show \
  --name "$ACR_NAME" \
  --query username \
  --output tsv)

export ACR_PASSWORD=$(az acr credential show \
  --name "$ACR_NAME" \
  --query "passwords[0].value" \
  --output tsv)
```

Do not print, commit, or share the password.

---

# 26. Initial Azure Container App Deployment

Set the Container App name:

```bash
export CONTAINERAPP_NAME="flask-app"
```

The initial deployment can be performed with:

```bash
az containerapp create \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --environment "$CONTAINERAPPS_ENVIRONMENT" \
  --image "$ACR_LOGIN_SERVER/flask-app:2.0" \
  --target-port 5000 \
  --ingress external \
  --min-replicas 1 \
  --max-replicas 3 \
  --cpu 0.5 \
  --memory 1.0Gi \
  --env-vars \
      APP_ENV=azure \
      APP_MESSAGE="Hello from Azure Container Apps" \
  --registry-server "$ACR_LOGIN_SERVER" \
  --registry-username "$ACR_USERNAME" \
  --registry-password "$ACR_PASSWORD"
```

After the initial deployment, Jenkins manages subsequent image updates automatically.

---

# 27. Azure Container Apps CI/CD Deployment

The Jenkins pipeline updates the Container App with the image produced by the current Jenkins build.

Example:

```bash
az containerapp update \
  --name flask-app \
  --resource-group flask-k8s-rg \
  --image flaskk8sacr1790962364.azurecr.io/flask-app:6
```

This means a successful Jenkins build can automatically promote the same application image from:

```text
GitHub
   |
   v
Jenkins
   |
   v
Docker Image
   |
   +--> Docker Hub
   |
   +--> Kind Kubernetes
   |
   +--> Azure Container Registry
             |
             v
      Azure Container Apps
```

---

# 28. Verify Azure Deployment

Check the Container App:

```bash
az containerapp show \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "{name:name,location:location,provisioningState:properties.provisioningState,fqdn:properties.configuration.ingress.fqdn}" \
  --output table
```

Final application:

```text
Name       Location       ProvisioningState
flask-app  Central India  Succeeded
```

---

# 29. Azure Container App Revision

List revisions:

```bash
az containerapp revision list \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

The final successful deployment used:

```text
Revision: flask-app--latest
```

The final deployment state was:

```text
Active:              True
Replicas:            1
Traffic Weight:      100%
Health State:        Healthy
Provisioning State:  Provisioned
```

---

# 30. Public Azure Endpoint

The application is publicly available through HTTPS.

```text
https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io
```

Health check:

```bash
curl https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io/health
```

Expected:

```text
ok
```

Application:

```text
https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io
```

The application is configured with:

```text
APP_ENV=azure
APP_MESSAGE=Hello from Azure Container Apps
```

CPU endpoint:

```bash
curl https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io/cpu
```

---

# 31. Final Azure Resources

```text
flask-k8s-rg
│
├── Azure Container Registry
│   └── flaskk8sacr1790962364
│       └── flask-app:<BUILD_NUMBER>
│
├── Container Apps Environment
│   └── flask-k8s-env
│
└── Container App
    └── flask-app
```

---

# 32. AKS Attempt and Quota Limitation

An AKS deployment was also attempted.

The command used was:

```bash
az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --attach-acr "$ACR_NAME"
```

The AKS cluster could not be created because the Azure for Students subscription did not have enough available regional vCPU quota.

The Azure error indicated:

```text
(ErrCode_InsufficientVCPUQuota)
Insufficient regional vcpu quota left for location centralindia.
left regional vcpu quota 1, requested quota 2.
```

Therefore, AKS was **not used as the successful cloud deployment**.

Instead, Azure Container Apps was used successfully.

This is an important part of the project because it demonstrates adapting the deployment architecture to the resource limitations of the available Azure subscription.

---

# 33. Useful Kubernetes Commands

Check nodes:

```bash
kubectl get nodes
```

Check Pods:

```bash
kubectl get pods
```

Check Services:

```bash
kubectl get svc
```

Check Deployments:

```bash
kubectl get deployments
```

Check HPA:

```bash
kubectl get hpa
```

Check resource usage:

```bash
kubectl top pods
kubectl top nodes
```

View logs:

```bash
kubectl logs <POD_NAME>
```

Follow logs:

```bash
kubectl logs -f <POD_NAME>
```

Describe a Pod:

```bash
kubectl describe pod <POD_NAME>
```

Restart the Deployment:

```bash
kubectl rollout restart deployment flask-app
```

Check rollout status:

```bash
kubectl rollout status deployment flask-app
```

---

# 34. Useful Azure Commands

List resources:

```bash
az resource list \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

Show the Container App:

```bash
az containerapp show \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP"
```

List revisions:

```bash
az containerapp revision list \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

List ACR image tags:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository flask-app \
  --output table
```

Check regional VM quota:

```bash
az vm list-usage \
  --location "$LOCATION" \
  --output table
```

---

# 35. Troubleshooting

## Metrics API unavailable

Check Metrics Server:

```bash
kubectl get pods -n kube-system | grep metrics
```

Then:

```bash
kubectl top nodes
kubectl top pods
```

If necessary, configure the Kind-specific kubelet arguments described in the Metrics Server section.

---

## Kind Service has `<pending>` external IP

This is expected for a local Kind cluster.

Use:

```bash
kubectl port-forward service/flask-service 8081:80
```

Then access:

```text
http://localhost:8081
```

---

## `ImagePullBackOff`

For locally built images, make sure the image has been loaded into Kind:

```bash
kind load docker-image flask-app:1.0 --name flask-k8s
```

Verify:

```bash
docker images | grep flask-app
```

For Jenkins deployments, verify that the current build image was loaded into Kind.

---

## HPA shows `<unknown>`

Check Metrics Server:

```bash
kubectl get pods -n kube-system | grep metrics
```

Then:

```bash
kubectl top pods
```

If metrics are unavailable, check the Metrics Server configuration.

---

## AKS creation fails because of quota

Check the regional quota:

```bash
az vm list-usage \
  --location "$LOCATION" \
  --output table
```

If the subscription does not have sufficient quota, request additional quota or use a subscription with sufficient capacity.

For this project, Azure Container Apps was used instead.

---

## Azure Container Apps revision fails

Check revisions:

```bash
az containerapp revision list \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

Verify the image exists:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository flask-app \
  --output table
```

Also verify:

* ACR credentials
* Container App target port
* Container App ingress configuration
* Container image tag
* Azure Container App logs

---

# 36. Security

Never commit sensitive information to GitHub.

Do not commit:

* Azure service principal secrets
* Azure passwords
* ACR passwords
* Docker Hub access tokens
* API keys
* SSH private keys
* `.env` files
* Cloud credentials
* Other production secrets

Jenkins credentials are stored in Jenkins Credential Manager and referenced by credential IDs in the pipeline.

The Kubernetes Secret in this demonstration contains a sample application message rather than a production credential.

For production environments, use a dedicated secret-management solution such as a cloud secret manager or Kubernetes-compatible secret-management system.

---

# 37. CI/CD Security Model

The Jenkins pipeline uses credentials for external services.

The pipeline references:

```text
dockerhub-creds
azure-sp
azure-tenant-id
```

The credentials are not written directly into the `Jenkinsfile`.

The Azure service principal is used by Jenkins to authenticate to Azure and perform the required deployment operations.

This provides a basic separation between:

```text
Source Code
     |
     v
Jenkins Pipeline
     |
     +--> Credentials
     |
     +--> Docker
     |
     +--> Kubernetes
     |
     +--> Azure
```

---

# 38. Final Results

## Local Kubernetes

```text
Platform:        Kind Kubernetes
Application:     Flask
Pods:            2 Running
Service:         flask-service
HPA:             2-5 replicas
CPU target:      50%
Metrics Server:  Working
Health probes:   Enabled
```

## Docker Hub

```text
Repository:      samkasaju/flask-app
Image tags:      Jenkins build numbers
Example:         flask-app:6
```

## Azure

```text
Registry:        Azure Container Registry
Registry:        flaskk8sacr1790962364.azurecr.io
Image:           flask-app:<BUILD_NUMBER>
Platform:        Azure Container Apps
Environment:     flask-k8s-env
Region:          Central India
Replicas:        1
Max replicas:    3
Revision:        flask-app--latest
Health:          Healthy
Provisioning:    Provisioned
Ingress:         HTTPS
```

## Jenkins

```text
Pipeline:        flask-k8s-pipeline
Source:          GitHub
Build System:    Jenkins
Testing:         pytest
Container Build: Docker
Local Deployment: Kind Kubernetes
Cloud Registry:  Azure Container Registry
Cloud Platform:  Azure Container Apps
```

---

# 39. End-to-End Deployment Flow

The final architecture can be summarized as:

```text
                    GitHub
                      |
                      v
                   Jenkins
                      |
             +--------+--------+
             |                 |
             v                 v
          pytest          Docker Build
                               |
                               v
                        flask-app:<BUILD>
                               |
                 +-------------+-------------+
                 |                           |
                 v                           v
             Docker Hub                    ACR
                 |                           |
                 v                           v
          Kind Kubernetes          Azure Container Apps
                 |                           |
                 v                           v
           Local Flask App            Public HTTPS App
```

The same application source code is therefore tested and packaged once by Jenkins and then deployed to both the local Kubernetes environment and Azure.

---

# 40. Conclusion

This project demonstrates an end-to-end DevOps workflow starting from application source code in GitHub and ending with an automatically deployed cloud application.

The local Kubernetes environment demonstrates:

* Docker containerization
* Kubernetes Deployments
* Kubernetes Services
* ConfigMaps
* Secrets
* Resource requests and limits
* Readiness probes
* Liveness probes
* Metrics Server
* Horizontal Pod Autoscaling

The CI/CD implementation demonstrates:

* GitHub integration
* Jenkins Pipeline
* Automated testing
* Docker image creation
* Docker Hub publishing
* Automated Kind deployment
* Azure Container Registry publishing
* Automated Azure Container Apps deployment
* Deployment verification

The Azure implementation demonstrates:

* Azure Container Registry
* Azure Container Apps
* Public HTTPS ingress
* Container App revisions
* Cloud deployment using a private container registry

An AKS deployment was attempted but could not be completed because the Azure for Students subscription did not have sufficient regional vCPU quota in Central India.

Azure Container Apps was therefore selected as the successful cloud deployment platform.

The final result is a working Flask application with a complete **GitHub → Jenkins → Docker → Kubernetes → Azure** CI/CD workflow.

---

# Author

**Sam Kasaju**

GitHub repository:

```text
https://github.com/samkasaju/flask-k8s

