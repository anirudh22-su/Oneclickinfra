pipeline {
    agent any

    environment {
        // Replication password used inside deploy.sh -> Ansible
        REPL_PASS = "StrongReplicationPass1!"
    }

    stages {

        stage('Checkout from GitHub') {
            steps {
                // Jenkins will actually do checkout for you when using "Pipeline from SCM",
                // but this stage is harmless if you later switch to "Pipeline script".
                echo "✅ Code already fetched from GitHub workspace"
                sh 'ls -R'
            }
        }

        stage('Terraform Init') {
            steps {
                sh '''
                cd terraform
                terraform init
                '''
            }
        }

        stage('Terraform Apply') {
            steps {
                sh '''
                cd terraform
                terraform apply -auto-approve
                '''
            }
        }

        stage('Deploy PostgreSQL with Ansible') {
            steps {
                sh '''
                cd ${WORKSPACE}
                chmod +x deploy.sh
                ./deploy.sh
                '''
            }
        }
    }
}
