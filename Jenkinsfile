
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
    }
}
