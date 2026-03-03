pipeline {
    agent any
    environment {
        GCP_PROJECT_ID = credentials('gcp-project-id')
        GKE_APPLICATION_CLUSTER_NAME = "application-gke-cluster"
        GKE_DATABASE_CLUSTER_NAME = "database-gke-cluster"
        GCP_ZONE = "asia-south1-a"
        
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        AZURE_RESOURCE_GROUP = "rg-hybrid"
        AKS_APPLICATION_CLUSTER_NAME = "application-aks-cluster"
        AKS_DATABASE_CLUSTER_NAME = "database-aks-cluster"
    }
    
    stages {
	/*
        stage('Fix Git') {
            steps {
                sh "git config --global --add safe.directory '*'"
            }
        }
        stage('Checkout Code') {
            steps {
                git branch: 'main',
                    credentialsId: 'git-cred',
                    url: 'https://github.com/srjbis/cloud-deploy.git'
            }
        }
	*/
        stage('Connect to GKE DATABASE') {
			steps {
				sh '''
				gcloud config set project $GCP_PROJECT_ID
				gcloud container clusters get-credentials $GKE_DATABASE_CLUSTER_NAME --zone $GCP_ZONE
				'''
            }
        }
        stage('Verify Connection to gke database') {
            steps {
                sh 'kubectl get nodes'
            }
        }
        stage('Deploy to GKE DATABASE') {
            steps {
                sh '''
                kubectl apply -f database-deployment.yaml
                '''
            }
        }
        stage('Wait for Redis IP in GKE') {
            steps {
                script {

                    def REDIS_IP = ""

                    timeout(time: 5, unit: 'MINUTES') {
                        while (!REDIS_IP) {
                            REDIS_IP = sh(
                                script: "kubectl get svc redis-lb -n data -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true",
                                returnStdout: true
                            ).trim()

                            if (!REDIS_IP) {
                                echo "Waiting for Redis external IP..."
                                sleep time: 10, unit: 'SECONDS'
                            }
                        }
                    }
                    echo "Redis IP acquired: ${REDIS_IP}"
                    // Save for later stages
                    env.REDIS_IP = REDIS_IP
                }
            }
        }
        stage('Connect to GKE APPLICATION') {
			steps {
				sh '''
				gcloud config set project $GCP_PROJECT_ID
				gcloud container clusters get-credentials $GKE_APPLICATION_CLUSTER_NAME --zone $GCP_ZONE
				'''
            }
        }
        stage('Verify Connection to gke application') {
            steps {
                sh 'kubectl get nodes'
            }
        }
        stage('Deploy App to GKE APPLICATION') {
            steps {
                script {
                    sh """
                    export REDIS_HOST=${REDIS_IP}
                    envsubst < application-production-stack.yaml | kubectl apply -f -
                    """
                }
            }
        }
        stage('Azure Login') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: '4b17e6b1-73ab-4b2f-9bae-8342cc46e89a',
                    usernameVariable: 'AZURE_CLIENT_ID',
                    passwordVariable: 'AZURE_CLIENT_SECRET'
                )]) {
                    sh '''
                    az login --service-principal \
                      -u $AZURE_CLIENT_ID \
                      -p $AZURE_CLIENT_SECRET \
                      --tenant $AZURE_TENANT_ID

                    az account set --subscription $AZURE_SUBSCRIPTION_ID
                    '''
                }
            }
        }
        stage('Connect to AKS database') {
            steps {
                sh '''
                az aks get-credentials \
                  --resource-group $AZURE_RESOURCE_GROUP \
                  --name $AKS_DATABASE_CLUSTER_NAME \
                  --overwrite-existing
                '''
            }
        }
        stage('Verify Connection to database aks') {
            steps {
                sh 'kubectl get nodes'
            }
        }
        stage('Deploy to AKS database') {
            steps {
                sh '''
                kubectl apply -f database-deployment.yaml
                '''
            }
        }
        stage('Wait for Redis IP in AKS') {
            steps {
                script {

                    def REDIS_IP = ""

                    timeout(time: 5, unit: 'MINUTES') {
                        while (!REDIS_IP) {
                            REDIS_IP = sh(
                                script: "kubectl get svc redis-lb -n data -o jsonpath='{.status.loadBalancer.ingress[0].ip}' || true",
                                returnStdout: true
                            ).trim()

                            if (!REDIS_IP) {
                                echo "Waiting for Redis external IP..."
                                sleep time: 10, unit: 'SECONDS'
                            }
                        }
                    }
                    echo "Redis IP acquired: ${REDIS_IP}"
                    // Save for later stages
                    env.REDIS_IP = REDIS_IP
                }
            }
        }
        stage('Connect to AKS APPLICATION') {
            steps {
                sh '''
                az aks get-credentials \
                  --resource-group $AZURE_RESOURCE_GROUP \
                  --name $AKS_APPLICATION_CLUSTER_NAME \
                  --overwrite-existing
                '''
            }
        }
        stage('Verify Connection to app aks') {
            steps {
                sh 'kubectl get nodes'
            }
        }
        stage('Deploy App to AKS') {
            steps {
                script {
                    sh """
                    export REDIS_HOST=${REDIS_IP}
                    envsubst < application-production-stack.yaml | kubectl apply -f -
                    """
                }
            }
        }
    }
}
