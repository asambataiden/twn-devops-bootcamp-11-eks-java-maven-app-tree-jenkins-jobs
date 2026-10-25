
pipeline {
    agent any

    stages {
        stage('Verify AWS Identity') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-capstone-01'
                ]]) {
                    sh '''
                        set +x
                        docker run --rm \
                          -e AWS_ACCESS_KEY_ID \
                          -e AWS_SECRET_ACCESS_KEY \
                          -e AWS_SESSION_TOKEN \
                          -e AWS_DEFAULT_REGION=eu-north-1 \
                          --entrypoint aws \
                          public.ecr.aws/aws-cli/aws-cli:2.31.22 \
                          sts get-caller-identity
                    '''
                }
            }
        }
    }
}
