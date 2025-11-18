pipeline {
    agent any

    environment {
        REPL_PASS = "StrongReplicationPass1!"
        AWS_REGION = "us-east-1"
    }

    stages {
        stage('Terraform Init') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    cd terraform
                    terraform init
                    '''
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
                    sh '''
                    cd terraform
                    terraform apply -auto-approve
                    '''
                }
            }
        }

        stage('Deploy PostgreSQL via Ansible') {
            steps {
                sh '''
                cd $WORKSPACE
                chmod +x deploy.sh
                ./deploy.sh
                '''
            }
        }
    }
}
