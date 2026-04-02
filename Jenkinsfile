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
    }
    triggers {
        githubPush()
    }
    stages {
        stage('Terraform Init') {
            steps {
                sh '''
                cd terraform-gke
                terraform init
                '''
            }
        }
        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }
        stage('Terraform Plan') {
            steps {
                //sh "terraform plan -var-file=\"${WORKSPACE}/terraform-gke/envs/dev/dev.tfvars\" -out=tfplan".
                sh "terraform -chdir=/var/jenkins_home/workspace/auto-deploy/terraform-gke plan -var-file=envs/dev/dev.tfvars -out=tfplan"
                sh "terraform show -json tfplan > plan.json"
            }
        }
        stage('Approval') {
            steps {
                input message: 'Approve Terraform Apply?'
            }
        }
        stage('Cost Estimation') {
            steps {
                sh '''
                infracost breakdown --path . --format json --out-file infracost.json
                infracost output --path infracost.json --format table > cost.txt
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
                    to: "talk2surajbiswas@gmail.com"
                )
            }
        }
        stage('Approval Gate') {
            steps {
                input message: "Approve Terraform Apply after cost review?"
            }
        }
        
    }
}
