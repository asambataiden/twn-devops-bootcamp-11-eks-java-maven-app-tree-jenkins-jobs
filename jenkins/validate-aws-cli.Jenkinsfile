pipeline {
    agent any
    options { timestamps() }
    stages {
        stage('Validate containerized AWS CLI') {
            steps {
                sh '''
                    set -eu
                    docker run --rm \
                      --entrypoint aws \
                      public.ecr.aws/aws-cli/aws-cli:2.31.22 \
                      --version
                '''
            }
        }
    }
}
