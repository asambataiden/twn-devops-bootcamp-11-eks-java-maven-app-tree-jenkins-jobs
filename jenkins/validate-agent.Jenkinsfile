pipeline {
    agent any

    options {
        timestamps()
    }

    stages {
        stage('Inspect Jenkins Agent') {
            steps {
                sh '''
                    set -eu

                    echo '=== Execution context ==='
                    id
                    uname -a
                    echo "PATH=$PATH"

                    echo '=== Java ==='
                    command -v java || true
                    java -version || true

                    echo '=== Maven ==='
                    command -v mvn || true
                    mvn -version || true

                    echo '=== Docker ==='
                    command -v docker || true
                    docker version || true

                    echo '=== AWS CLI ==='
                    command -v aws || true
                    aws --version || true

                    echo '=== Kubernetes CLI ==='
                    command -v kubectl || true
                    kubectl version --client || true

                    echo '=== envsubst ==='
                    command -v envsubst || true
                    envsubst --version || true
                '''
            }
        }
    }
}
