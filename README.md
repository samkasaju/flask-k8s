# Flask Kubernetes and Azure Container Apps Deployment

A containerized Flask application deployed locally with Kubernetes (Kind) and in Azure using Azure Container Registry (ACR) and Azure Container Apps.

## Project Overview

This project demonstrates a basic DevOps and container orchestration workflow:

1. Build a Flask application.
2. Containerize it using Docker.
3. Run the application locally.
4. Deploy it to a local Kubernetes cluster using Kind.
5. Configure Kubernetes resources:

   * Deployment
   * Service
   * ConfigMap
   * Secret
   * Resource requests and limits
   * Readiness probe
   * Liveness probe
   * Horizontal Pod Autoscaler (HPA)
6. Store the container image in Azure Container Registry.
7. Deploy the application to Azure Container Apps.
8. Expose the application through a public HTTPS endpoint.

## Architecture

### Local Kubernetes

```text
Flask Application
       |
       v
   Docker Image
       |
       v
Kind Kubernetes Cluster
       |
       +-- Deployment
       |     +-- Pod 1
       |     +-- Pod 2
       |
       +-- Service
       |
       +-- ConfigMap
       |
       +-- Secret
       |
       +-- Readiness Probe
       |
       +-- Liveness Probe
       |
       +-- Resource Requests/Limits
       |
       +-- Metrics Server
       |
       +-- HPA (2-5 replicas)
```

### Azure

```text
Flask Application
       |
       v
   Docker Image
       |
       v
Azure Container Registry
       |
       | flask-app:2.0
       v
Azure Container Apps
       |
       v
Public HTTPS Endpoint
```

## Project Structure

```text
flask-k8s/
├── app.py
├── requirements.txt
├── Dockerfile
├── k8s.yaml
├── .gitignore
└── README.md
```

## Prerequisites

The project was developed on Ubuntu 24.04.

Required tools:

* Python 3
* Docker
* kubectl
* Kind
* Azure CLI
* Git

Check the installations:

```bash
docker --version
kubectl version --client
kind version
az version
git --version
```

## 1. Flask Application

The Flask application contains three endpoints.

### `/`

Returns the application message and environment variables.

### `/health`

Used by Kubernetes for readiness and liveness checks.

Expected response:

```text
ok
```

### `/cpu`

Performs a CPU-intensive calculation. This endpoint can be used to generate CPU load when testing autoscaling.

## 2. Docker

Build the Docker image:

```bash
docker build -t flask-app:1.0 .
```

Run it locally:

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

## 3. Create a Kind Kubernetes Cluster

Create the cluster:

```bash
kind create cluster --name flask-k8s
```

Verify:

```bash
kubectl cluster-info
kubectl get nodes
```

The Kubernetes context is:

```text
kind-flask-k8s
```

## 4. Load the Docker Image into Kind

Load the locally built image into the Kind cluster:

```bash
kind load docker-image flask-app:1.0 --name flask-k8s
```

Verify the local image:

```bash
docker images | grep flask-app
```

## 5. Deploy to Kubernetes

The `k8s.yaml` file contains:

* ConfigMap
* Secret
* Deployment
* Service
* HorizontalPodAutoscaler

Apply the configuration:

```bash
kubectl apply -f k8s.yaml
```

Verify:

```bash
kubectl get all
```

## 6. ConfigMap

The ConfigMap provides the environment:

```text
APP_ENV=kubernetes
```

View it:

```bash
kubectl get configmap flask-config -o yaml
```

## 7. Secret

The Kubernetes Secret provides the application message:

```text
APP_MESSAGE=Hello from Kubernetes
```

View the Secret metadata:

```bash
kubectl get secret flask-secret
```

Do not store real production credentials directly in Git.

## 8. Deployment

The Deployment runs two replicas.

Check:

```bash
kubectl get deployment
kubectl get pods
```

The final local deployment had two running Flask pods:

```text
flask-app-69885967f4-6pg67   1/1   Running
flask-app-69885967f4-x5qgx   1/1   Running
```

The container configuration includes:

```text
Image: flask-app:1.0
Container port: 5000
Image pull policy: IfNotPresent
```

## 9. Resource Requests and Limits

Each pod is configured with:

```yaml
requests:
  cpu: "100m"
  memory: "128Mi"

limits:
  cpu: "500m"
  memory: "256Mi"
```

This allows Kubernetes to schedule the workload while limiting the maximum CPU and memory available to each container.

Inspect the deployment:

```bash
kubectl describe deployment flask-app
```

## 10. Health Probes

The application exposes:

```text
/health
```

Kubernetes uses this endpoint for both:

* Readiness probe
* Liveness probe

Inspect a pod:

```bash
kubectl describe pod <POD_NAME>
```

A readiness probe determines whether a pod is ready to receive traffic.

A liveness probe helps Kubernetes detect an unhealthy container and restart it when necessary.

## 11. Access the Application in Kind

The Kubernetes Service is:

```text
flask-service
```

Kind runs locally inside Docker and does not automatically provide a cloud load balancer IP.

Port-forward the Service:

```bash
kubectl port-forward service/flask-service 5000:80
```

Then test:

```bash
curl http://localhost:5000/
curl http://localhost:5000/health
curl http://localhost:5000/cpu
```

The Service showed `<pending>` for `EXTERNAL-IP`, which is expected for this local Kind setup.

## 12. Metrics Server

The HPA requires resource metrics.

Install Metrics Server:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For the Kind environment, the following arguments were added:

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

Verify metrics:

```bash
kubectl top nodes
kubectl top pods
```

## 13. Horizontal Pod Autoscaler

The project uses:

```text
Minimum replicas: 2
Maximum replicas: 5
CPU target: 50%
```

Check the HPA:

```bash
kubectl get hpa
```

The final local HPA showed:

```text
NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS
flask-hpa   Deployment/flask-app   cpu: 1%/50%   2         5         2
```

Generate CPU load:

```bash
for i in {1..1000}; do
  curl -s http://localhost:5000/cpu > /dev/null &
done
wait
```

Monitor autoscaling:

```bash
kubectl get hpa -w
```

And:

```bash
kubectl get pods -w
```

## 14. Azure CLI

Log in:

```bash
az login
```

Check the active subscription:

```bash
az account show --output table
```

The project used an Azure for Students subscription.

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

## 15. Azure Container Registry

Create ACR:

```bash
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic
```

Get the registry login server:

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

## 16. Build the Image in ACR

The registry ultimately contained:

```text
1.0
1.1
2.0
```

The final successfully deployed image was:

```text
flask-app:2.0
```

The image was built in Azure using:

```bash
az acr build \
  --registry "$ACR_NAME" \
  --image flask-app:2.0 \
  .
```

Verify the image tags:

```bash
az acr repository show-tags \
  --name "$ACR_NAME" \
  --repository flask-app \
  --output table
```

## 17. AKS Attempt and Quota Limitation

An AKS cluster was attempted with:

```bash
az aks create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$AKS_NAME" \
  --node-count 1 \
  --node-vm-size Standard_B2s \
  --generate-ssh-keys \
  --attach-acr "$ACR_NAME"
```

The cluster could not be created because the Azure for Students subscription did not have enough available regional vCPU quota.

The returned error was:

```text
(ErrCode_InsufficientVCPUQuota)
Insufficient regional vcpu quota left for location centralindia.
left regional vcpu quota 1, requested quota 2.
```

Therefore, AKS was not used as the successful Azure deployment.

The successful cloud deployment described below uses Azure Container Apps.

## 18. Azure Container Apps Environment

Register the required providers:

```bash
az provider register --namespace Microsoft.App
az provider register --namespace Microsoft.OperationalInsights
```

Create the environment:

```bash
export CONTAINERAPPS_ENVIRONMENT="flask-k8s-env"

az containerapp env create \
  --name "$CONTAINERAPPS_ENVIRONMENT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION"
```

## 19. ACR Authentication

The Container Apps environment used registry credentials to pull the private ACR image.

Enable ACR admin credentials:

```bash
az acr update \
  --name "$ACR_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --admin-enabled true
```

Retrieve credentials into shell variables:

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

Do not print or commit the password.

## 20. Deploy to Azure Container Apps

Set the Container App name:

```bash
export CONTAINERAPP_NAME="flask-app"
```

Deploy:

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

## 21. Verify Azure Deployment

Check the application:

```bash
az containerapp show \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query "{name:name,location:location,provisioningState:properties.provisioningState,fqdn:properties.configuration.ingress.fqdn}" \
  --output table
```

Final result:

```text
Name       Location       ProvisioningState
flask-app  Central India  Succeeded
```

Public hostname:

```text
flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io
```

## 22. Verify the Container App Revision

List revisions:

```bash
az containerapp revision list \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --output table
```

Final revision:

```text
flask-app--latest
```

Final state:

```text
Active:             True
Replicas:           1
Traffic Weight:     100
Health State:       Healthy
Provisioning State: Provisioned
```

## 23. Test the Public HTTPS Endpoint

Set the URL:

```bash
export APP_URL=$(az containerapp show \
  --name "$CONTAINERAPP_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --query properties.configuration.ingress.fqdn \
  --output tsv)
```

Health check:

```bash
curl "https://$APP_URL/health"
```

Expected:

```text
ok
```

Application endpoint:

```bash
curl "https://$APP_URL/"
```

Expected:

```text
Hello from Flask! ENV=azure MESSAGE=Hello from Azure Container Apps
```

CPU endpoint:

```bash
curl "https://$APP_URL/cpu"
```

The deployed application successfully returned:

```text
41666654166667500000
```

## 24. Final Azure Resources

```text
flask-k8s-rg
│
├── Azure Container Registry
│   └── flask-app:2.0
│
├── Container Apps Environment
│   └── flask-k8s-env
│
└── Container App
    └── flask-app
```

## 25. Useful Kubernetes Commands

Check nodes:

```bash
kubectl get nodes
```

Check pods:

```bash
kubectl get pods
```

Check services:

```bash
kubectl get svc
```

Check deployments:

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

Describe a pod:

```bash
kubectl describe pod <POD_NAME>
```

Restart the deployment:

```bash
kubectl rollout restart deployment flask-app
```

Check rollout status:

```bash
kubectl rollout status deployment flask-app
```

## 26. Useful Azure Commands

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

List image tags:

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

## 27. Troubleshooting

### Metrics API unavailable

Install Metrics Server:

```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

For Kind, add the required kubelet arguments and restart Metrics Server.

### Kind Service has `<pending>` external IP

This is expected for a local Kind cluster.

Use:

```bash
kubectl port-forward service/flask-service 5000:80
```

### `ImagePullBackOff`

For locally built images:

```bash
kind load docker-image flask-app:1.0 --name flask-k8s
```

Then verify:

```bash
docker images | grep flask-app
```

### HPA shows `<unknown>`

Check Metrics Server:

```bash
kubectl get pods -n kube-system | grep metrics
```

Then:

```bash
kubectl top pods
```

### AKS creation fails because of quota

Check:

```bash
az vm list-usage \
  --location "$LOCATION" \
  --output table
```

If the subscription does not have sufficient quota, request additional quota or use a subscription with sufficient capacity.

### Azure Container Apps revision fails

Check the revisions:

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

## 28. Security Notes

Never commit:

* Azure passwords
* ACR passwords
* API keys
* SSH private keys
* `.env` files
* Cloud credentials

The `.gitignore` file excludes common local secrets and environment files.

The Kubernetes Secret in this demonstration contains a sample message rather than a production credential.

For production workloads, use a dedicated secret-management solution rather than committing sensitive values to Kubernetes manifests.

## 29. Final Results

### Local Kubernetes

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

### Azure

```text
Registry:        Azure Container Registry
Image:           flask-app:2.0
Platform:        Azure Container Apps
Region:          Central India
Replicas:        1
Revision:        flask-app--latest
Health:          Healthy
Provisioning:    Provisioned
Ingress:         HTTPS
```

### Public Endpoint

https://flask-app.delightfulwater-b02b5bef.centralindia.azurecontainerapps.io

## Conclusion

This project demonstrates the path from a Flask application to a Docker container, a local Kubernetes deployment, and a public Azure deployment.

The local Kubernetes environment demonstrates Deployments, Services, ConfigMaps, Secrets, health probes, resource management, Metrics Server, and Horizontal Pod Autoscaling.

The Azure portion demonstrates Azure Container Registry and Azure Container Apps.

An AKS deployment was attempted, but the Azure for Students subscription's available regional vCPU quota prevented the AKS cluster from being created. Azure Container Apps was therefore used for the successful cloud deployment.
