pipeline {
    agent any

    environment {
        DOCKER_IMAGE = 'sivasakthi08/trendify-app'
        IMAGE_TAG = '1.0'
    }

    stages {
        stage('Verify Source Code') {
            steps {
                echo 'Trendify pipeline started!'
                sh 'pwd'
                sh 'ls -la'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $DOCKER_IMAGE:$IMAGE_TAG .'
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'dockerhub-creds',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_TOKEN'
                )]) {
                    sh '''
                        echo "$DOCKER_TOKEN" | docker login -u "$DOCKER_USER" --password-stdin
                        docker push $DOCKER_IMAGE:$IMAGE_TAG
                        docker logout
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig --region ap-south-1 --name trendify-eks-cluster
                    kubectl apply -f k8s/
                    kubectl rollout restart deployment/trendify-deployment
                    kubectl rollout status deployment/trendify-deployment --timeout=180s
                    kubectl get deployments,pods,services -n default
                '''
            }
        }
    }
}
