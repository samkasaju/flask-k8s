pipeline {
    agent any

    environment {
        IMAGE_NAME = "flask-app"
        IMAGE_TAG = "${BUILD_NUMBER}"

        // Docker Hub
        DOCKERHUB_REPO = "samkasaju/flask-app"

        // Azure Container Registry
        ACR_LOGIN_SERVER = "flaskk8sacr1790962364.azurecr.io"
        ACR_REPO = "flaskk8sacr1790962364.azurecr.io/flask-app"

        // Azure Container Apps
        RESOURCE_GROUP = "flask-k8s-rg"
        CONTAINER_APP = "flask-app"
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Test') {
            steps {
                sh '''
                    python3 -m venv .venv
                    . .venv/bin/activate
                    pip install --upgrade pip
                    pip install -r requirements.txt
                    python -m pytest
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKERHUB_USER',
                        passwordVariable: 'DOCKERHUB_TOKEN'
                    )
                ]) {
                    sh '''
                        echo "$DOCKERHUB_TOKEN" | docker login \
                            -u "$DOCKERHUB_USER" \
                            --password-stdin

                        docker tag ${IMAGE_NAME}:${IMAGE_TAG} \
                            ${DOCKERHUB_REPO}:${IMAGE_TAG}

                        docker push ${DOCKERHUB_REPO}:${IMAGE_TAG}

                        docker logout
                    '''
                }
            }
        }

        stage('Load Image into Kind') {
            steps {
                sh '''
                    kind load docker-image \
                        ${IMAGE_NAME}:${IMAGE_TAG} \
                        --name flask-k8s
                '''
            }
        }

        stage('Deploy to Kubernetes') {
            steps {
                sh '''
                    kubectl set image deployment/flask-app \
                        flask-app=${IMAGE_NAME}:${IMAGE_TAG}

                    kubectl rollout status deployment/flask-app
                '''
            }
        }

        stage('Verify Kubernetes Deployment') {
            steps {
                sh '''
                    kubectl get pods
                    kubectl get deployment flask-app
                    kubectl get service flask-service
                '''
            }
        }

        stage('Push to Azure Container Registry') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'azure-sp',
                        usernameVariable: 'AZURE_CLIENT_ID',
                        passwordVariable: 'AZURE_CLIENT_SECRET'
                    ),
                    string(
                        credentialsId: 'azure-tenant-id',
                        variable: 'AZURE_TENANT_ID'
                    )
                ]) {
                    sh '''
                        az login \
                            --service-principal \
                            --username "$AZURE_CLIENT_ID" \
                            --password "$AZURE_CLIENT_SECRET" \
                            --tenant "$AZURE_TENANT_ID"

                        az acr login \
                            --name flaskk8sacr1790962364

                        docker tag \
                            ${IMAGE_NAME}:${IMAGE_TAG} \
                            ${ACR_REPO}:${IMAGE_TAG}

                        docker push \
                            ${ACR_REPO}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to Azure Container Apps') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'azure-sp',
                        usernameVariable: 'AZURE_CLIENT_ID',
                        passwordVariable: 'AZURE_CLIENT_SECRET'
                    ),
                    string(
                        credentialsId: 'azure-tenant-id',
                        variable: 'AZURE_TENANT_ID'
                    )
                ]) {
                    sh '''
                        az login \
                            --service-principal \
                            --username "$AZURE_CLIENT_ID" \
                            --password "$AZURE_CLIENT_SECRET" \
                            --tenant "$AZURE_TENANT_ID"

                        az containerapp update \
                            --name "$CONTAINER_APP" \
                            --resource-group "$RESOURCE_GROUP" \
                            --image "${ACR_REPO}:${IMAGE_TAG}"
                    '''
                }
            }
        }

        stage('Verify Azure Deployment') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'azure-sp',
                        usernameVariable: 'AZURE_CLIENT_ID',
                        passwordVariable: 'AZURE_CLIENT_SECRET'
                    ),
                    string(
                        credentialsId: 'azure-tenant-id',
                        variable: 'AZURE_TENANT_ID'
                    )
                ]) {
                    sh '''
                        az login \
                            --service-principal \
                            --username "$AZURE_CLIENT_ID" \
                            --password "$AZURE_CLIENT_SECRET" \
                            --tenant "$AZURE_TENANT_ID"

                        az containerapp show \
                            --name "$CONTAINER_APP" \
                            --resource-group "$RESOURCE_GROUP" \
                            --query "{name:name,provisioningState:properties.provisioningState,runningStatus:properties.runningStatus}" \
                            -o table
                    '''
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline finished.'
        }

        success {
            echo 'CI/CD pipeline completed successfully!'
        }

        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
    }
}
