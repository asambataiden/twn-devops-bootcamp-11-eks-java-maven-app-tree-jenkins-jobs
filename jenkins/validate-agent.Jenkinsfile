pipeline {
    agent any

    tools {
        maven 'maven-3.9'
    }

    options {
        timestamps()
    }

    stages {
        stage('Verify Java and Jenkins-managed Maven') {
            steps {
                sh '''
                    set -eu
                    echo '=== Java ==='
                    java -version
                    echo '=== Maven ==='
                    mvn -version
                '''
            }
        }

        stage('Inspect deployment utilities') {
            steps {
                sh '''
                    echo '=== Docker ==='
                    docker version || true
                    echo '=== AWS CLI ==='
                    if command -v aws >/dev/null 2>&1; then aws --version; else echo 'AWS CLI is not installed on this agent'; fi
                    echo '=== Kubernetes CLI ==='
                    kubectl version --client || true
                    echo '=== envsubst ==='
                    envsubst --version || true
                '''
            }
        }
    }
}
