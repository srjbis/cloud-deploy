pipeline {
    agent any
	/* parameters {
        string(name: 'PROJECT_ID', defaultValue: 'my-project')
        string(name: 'ZONE', defaultValue: 'asia-south1-a')
    } */
    environment {
        GCP_PROJECT_ID = credentials('gcp-project-id')
        GKE_APPLICATION_CLUSTER_NAME = "application-gke-cluster"
        GKE_DATABASE_CLUSTER_NAME = "database-gke-cluster"
        GCP_ZONE = "asia-south1-a"
		TF_VAR_project_id = credentials('gcp-project-id')
		// TF_VAR_zone     = "asia-south1-a"
        
        AZURE_TENANT_ID = credentials('azure-tenant-id')
        AZURE_SUBSCRIPTION_ID = credentials('azure-subscription-id')
        AZURE_RESOURCE_GROUP = "rg-hybrid"
        AKS_APPLICATION_CLUSTER_NAME = "application-aks-cluster"
        AKS_DATABASE_CLUSTER_NAME = "database-aks-cluster"
        INFRACOST_API_KEY = credentials('infracost-api-key')
        TF_DIR = "${WORKSPACE}/terraform/envs/dev" // for now it is hardcode but in future it will be input specific
    }
    options {
        durabilityHint('MAX_SURVIVABILITY')
        disableConcurrentBuilds()
    }
    triggers {
        githubPush()
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh "terraform -chdir=$TF_DIR init"
            }
        }
        stage('Terraform Validate') {
            steps {
                sh "terraform -chdir=$TF_DIR validate -no-color"
            }
        }
        stage('Terraform Plan') {
            steps {
                sh "terraform -chdir=$TF_DIR plan -no-color -var-file=dev.tfvars -out=tfplan"
                sh "terraform -chdir=$TF_DIR show -no-color -json tfplan > plan.json"
            }
        }
        stage('Cost Estimation') {
            steps {
                sh '''
                infracost breakdown --path . --format json --out-file infracost.json
                infracost output --path infracost.json --format table > cost.txt
                cat cost.txt
                '''
            }
        }
        stage('Send Cost to Approver') {
            steps {
                emailext (
                    subject: "Terraform Cost Estimate",
                    body: """
                    Please review the cost before approval.

                    Cost details:
                    ${readFile('cost.txt')}

                    Approve in Jenkins UI.
                    """,
                    to: "reach2surajbiswas@gmail.com"
                )
            }
        }
        stage('Approval Gate - 1') {
            steps {
                input message: "Approve Terraform Apply after cost review?"
            }
        }
        stage('Apply') {
            steps {
                timeout(time: 90, unit: 'MINUTES') {
                    sh "terraform -chdir=$TF_DIR apply -no-color tfplan | tee apply.log"
                }
            }
        }
        stage('Argocd-app Terraform Init') {
            steps {
                sh "terraform -chdir=$TF_DIR/argocd-app init"
            }
        }
        stage('Argocd-app Terraform Validate') {
            steps {
                sh "terraform -chdir=$TF_DIR/argocd-app validate -no-color"
            }
        }
        stage('Argocd-app Terraform plan') {
            steps {
                sh "terraform -chdir=$TF_DIR/argocd-app plan -no-color -out=tfplan"
            }
        }
        stage('Approval Gate - 2') {
            steps {
                input message: "Approve Terraform Apply?"
            }
        }
        stage('Apply AgroCD app') {
            steps {
                timeout(time: 90, unit: 'MINUTES') {
                    sh "terraform -chdir=$TF_DIR/agrocd-app apply -no-color tfplan | tee apply.log"
                }
            }
        }
    }
    post {
        always {
            deleteDir()
        }
    }
}
