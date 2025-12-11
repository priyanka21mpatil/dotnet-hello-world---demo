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
        IMAGE_NAME = "2111docker/dotnet-hello-world"
        IMAGE_TAG  = "${BUILD_NUMBER}"

        UAT_EC2_IP  = "54.226.198.192"
        PROD_EC2_IP = "35.172.199.103"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'dev',
                    url: 'https://github.com/priyanka21mpatil/dotnet-hello-world---demo',
                    credentialsId: 'github-creds' // if private
            }
        }

        stage('Verify Docker') {
            steps {
                sh "docker --version"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh "docker build -t ${IMAGE_NAME}:${IMAGE_TAG} ."
            }
        }

        stage('Docker Login & Push') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-user',
                    usernameVariable: 'DH_USER',
                    passwordVariable: 'DH_PASS'
                )]) {
                    sh '''
                        echo "$DH_PASS" | docker login -u "$DH_USER" --password-stdin
                        docker push ${IMAGE_NAME}:${IMAGE_TAG}
                    '''
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                script {
                    def TARGET_IP  = (params.DEPLOY_ENV == 'UAT') ? env.UAT_EC2_IP : env.PROD_EC2_IP
                    def KEY_ID     = (params.DEPLOY_ENV == 'UAT') ? 'ssh-key-uat'  : 'ssh-key-prod'

                    withCredentials([sshUserPrivateKey(
                        credentialsId: KEY_ID,
                        keyFileVariable: 'SSH_KEY'
                    )]) {
                        sh """
                            ssh -o StrictHostKeyChecking=no -i \$SSH_KEY ec2-user@${TARGET_IP} '
                                sudo docker pull ${IMAGE_NAME}:${IMAGE_TAG} &&
                                sudo docker stop dotnetapp || true &&
                                sudo docker rm dotnetapp || true &&
                                sudo docker run -d --name dotnetapp -p 80:80 ${IMAGE_NAME}:${IMAGE_TAG}
                            '
                        """
                    }
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
                            echo "Health check FAILED with status \$STATUS"
                            exit 1
                        fi
                    """
                }
            }
        }
    }
}
