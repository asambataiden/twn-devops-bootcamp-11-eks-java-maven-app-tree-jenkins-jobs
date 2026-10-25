
pipeline {
    agent any

    tools {
        jdk 'jdk-21'
        maven 'maven-3.9'
    }

    stages {
        stage('Validate Jenkins Agent') {
            steps {
                sh '''
                    set -eu

                    java -version
                    mvn -version
                    docker version
                    aws --version
                    kubectl version --client
                    envsubst --version
                '''
            }
        }
    }
}
