pipeline {
    agent any

    environment {
        AWS_ACCESS_KEY_ID     = credentials('aws-access-key-id')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-access-key')
    }

    stages {

        stage('Checkout') {
            steps { checkout scm }
        }

        stage('Terraform Init') {
            steps {
                dir('terraform') {
                    sh 'terraform init -input=false -upgrade'
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    sh 'terraform apply -auto-approve -input=false'
                }
            }
        }

        stage('Configure PostgreSQL (Ansible)') {
            steps {
                withCredentials([
                    sshUserPrivateKey(credentialsId: 'oneclick-ssh-key', keyFileVariable: 'SSH_KEY'),
                    string(credentialsId: 'repl-password', variable: 'REPL_PASS')
                ]) {
                    sh '''
                        mkdir -p ~/.ssh
                        cp "$SSH_KEY" ~/.ssh/oneclick.pem
                        chmod 600 ~/.ssh/oneclick.pem
                        export REPL_PASS=$REPL_PASS
                        ./deploy.sh
                    '''
                }
            }
        }
    }

    post {
        always { echo "Pipeline finished!" }
        success { echo "🎉 Success: Multi-region DB deployed!" }
        failure { echo "❌ Failed: Check logs" }
    }
}
