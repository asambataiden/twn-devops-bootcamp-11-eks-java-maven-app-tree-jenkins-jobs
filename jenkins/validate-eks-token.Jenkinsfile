pipeline {
    agent any
    options { timestamps(); disableConcurrentBuilds() }
    environment {
        AWS_REGION = 'eu-north-1'
        EKS_CLUSTER_NAME = 'floral-mongoose-1792497995'
    }
    stages {
        stage('Verify EKS token generation') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-capstone-01',
                    accessKeyVariable: 'AWS_ACCESS_KEY_ID',
                    secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
                ]]) {
                    sh '''
                        set +x
                        set -eu
                        docker run --rm \
                          -e AWS_ACCESS_KEY_ID \
                          -e AWS_SECRET_ACCESS_KEY \
                          -e AWS_SESSION_TOKEN \
                          -e AWS_DEFAULT_REGION="$AWS_REGION" \
                          --entrypoint aws \
                          public.ecr.aws/aws-cli/aws-cli:2.31.22 \
                          eks get-token \
                          --cluster-name "$EKS_CLUSTER_NAME" \
                          --region "$AWS_REGION" \
                          --query 'status.expirationTimestamp' \
                          --output text
                        echo "EKS authentication token generated (token not logged)."
                    '''
                }
            }
        }
    }
}
