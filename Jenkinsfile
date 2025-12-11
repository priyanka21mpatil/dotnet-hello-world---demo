pipeline {
    agent any

    parameters {
        choice(
            name: 'DEPLOY_ENV',
            choices: ['UAT', 'PROD'],
            description: 'Choose deployment environment'
        )
    }

    environment {
        DOCKERHUB_USER = credentials('dockerhub-user')
        DOCKERHUB_PASS = credentials('dockerhub-pass')

        AWS_ACCESS_KEY_ID     = credentials('aws-access-key')
        AWS_SECRET_ACCESS_KEY = credentials('aws-secret-key')

        IMAGE_NAME = "2111docker/dotnet-hello-world"
        IMAGE_TAG  = "${env.BUILD_NUMBER}"

        // Environment-specific settings
        UAT_EC2_IP  = "ec2-uat-public-ip"
        PROD_EC2_IP = "ec2-prod-public-ip"

        UAT_SSH_KEY  = credentials('ssh-key-uat')
        PROD_SSH_KEY = credentials('ssh-key-prod')
    }

    stages {

        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/priyanka21mpatil/dotnet-hello-world---demo.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh """
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                """
            }
        }

        stage('Push to Docker Hub') {
            steps {
                sh """
                    echo ${DOCKERHUB_PASS} | docker login -u ${DOCKERHUB_USER} --password-stdin
                    docker push ${IMAGE_NAME}:${IMAGE_TAG}
                """
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def TARGET_IP   = (params.DEPLOY_ENV == 'UAT') ? env.UAT_EC2_IP   : env.PROD_EC2_IP
                    def TARGET_KEY  = (params.DEPLOY_ENV == 'UAT') ? env.UAT_SSH_KEY  : env.PROD_SSH_KEY

                    sh """
                        ssh -o StrictHostKeyChecking=no -i ${TARGET_KEY} ec2-user@${TARGET_IP} '
                            sudo docker pull ${IMAGE_NAME}:${IMAGE_TAG} &&
                            sudo docker stop dotnetapp || true &&
                            sudo docker rm dotnetapp || true &&
                            sudo docker run -d --name dotnetapp -p 80:80 ${IMAGE_NAME}:${IMAGE_TAG}
                        '
                    """
                }
            }
        }

        stage('Health Check') {
            steps {
                script {
                    def TARGET_IP = (params.DEPLOY_ENV == 'UAT') ? env.UAT_EC2_IP : env.PROD_EC2_IP

                    sh """
                        STATUS=\$(curl -s -o /dev/null -w "%{http_code}" http://${TARGET_IP})
                        if [ "\$STATUS" == "200" ]; then
                            echo "Health check PASSED"
                        else
                            echo "Health check FAILED"
                            exit 1
                        fi
                    """
                }
            }
        }
    }
}

