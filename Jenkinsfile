pipeline {
    agent any
    environment {
        GCP_PROJECT_ID = credentials('gcp-project-id')
        GKE_CLUSTER_NAME = "application-gke-cluster"
        GCP_ZONE = "asia-south1-a"
        
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        AZURE_RESOURCE_GROUP = "rg-hybrid"
        AKS_CLUSTER_NAME = "application-aks-cluster"
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
        stage('Connect to GKE') {
			steps {
				sh '''
				gcloud config set project $GCP_PROJECT_ID
				gcloud container clusters get-credentials $GKE_CLUSTER_NAME --zone $GCP_ZONE
				kubectl get nodes
				'''
            }
        }
        stage('Deploy to GKE') {
            steps {
                sh '''
                kubectl apply -f deployment.yaml
                '''
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
        stage('Connect to AKS') {
            steps {
                sh '''
                az aks get-credentials \
                  --resource-group $AZURE_RESOURCE_GROUP \
                  --name $AKS_CLUSTER_NAME \
                  --overwrite-existing
                '''
            }
        }
        stage('Verify Connection') {
            steps {
                sh 'kubectl get nodes'
            }
        }
        stage('Deploy to AKS') {
            steps {
                sh '''
                kubectl apply -f deployment.yaml
                '''
            }
        }
    }
}
