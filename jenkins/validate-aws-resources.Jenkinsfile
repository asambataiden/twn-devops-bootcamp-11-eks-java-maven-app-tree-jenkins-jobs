pipeline {
    agent any

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    environment {
        AWS_REGION = 'eu-north-1'
        AWS_ACCOUNT_ID = '591132357918'
        EKS_CLUSTER_NAME = 'floral-mongoose-1792497995'
        ECR_REPOSITORY = 'twn-devops-bootcamp/java-maven-app'
    }

    stages {
        stage('Validate AWS resources from Jenkins') {
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

                        aws_cli() {
                          docker run --rm \
                            -e AWS_ACCESS_KEY_ID \
                            -e AWS_SECRET_ACCESS_KEY \
                            -e AWS_SESSION_TOKEN \
                            -e AWS_DEFAULT_REGION="$AWS_REGION" \
                            --entrypoint aws \
                            public.ecr.aws/aws-cli/aws-cli:2.31.22 "$@"
                        }

                        echo "=== Verify AWS account ==="
                        account="$(aws_cli sts get-caller-identity --query Account --output text)"
                        test "$account" = "$AWS_ACCOUNT_ID"
                        echo "Expected AWS account confirmed."

                        echo "=== Verify ECR repository ==="
                        aws_cli ecr describe-repositories \
                          --repository-names "$ECR_REPOSITORY" \
                          --query 'repositories[].repositoryName' \
                          --output table

                        echo "=== Verify EKS cluster ==="
                        status="$(aws_cli eks describe-cluster \
                          --name "$EKS_CLUSTER_NAME" \
                          --query 'cluster.status' --output text)"
                        test "$status" = ACTIVE
                        echo "EKS cluster is ACTIVE."
                    '''
                }
            }
        }
    }
}
