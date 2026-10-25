pipeline {
    agent any
    tools {
        maven 'maven-3.9'
    }
    options {
        timestamps()
        disableConcurrentBuilds()
    }
    stages {
        stage('Build and test') {
            steps {
                sh 'mvn -B clean verify'
            }
            post {
                always {
                    junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }
        stage('Build Docker image') {
            steps {
                sh '''
                    set -eu
                    VERSION="$(mvn -q -DforceStdout help:evaluate -Dexpression=project.version | tail -n 1)"
                    test -n "$VERSION"
                    docker build --tag "twn-capstone-01-local:$VERSION-$BUILD_NUMBER" .
                    docker image inspect "twn-capstone-01-local:$VERSION-$BUILD_NUMBER" --format '{{.Id}}'
                '''
            }
        }
    }
}
