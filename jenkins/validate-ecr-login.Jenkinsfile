pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = 'eu-north-1'
    ECR_REGISTRY = '591132357918.dkr.ecr.eu-north-1.amazonaws.com'
  }
  stages {
    stage('Validate ECR Docker authentication') {
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
            export DOCKER_CONFIG="$(mktemp -d)"
            chmod 700 "$DOCKER_CONFIG"
            trap 'rm -rf "$DOCKER_CONFIG"' EXIT

            echo "=== Obtain short-lived ECR login password via containerized AWS CLI ==="
            docker run --rm \
              -e AWS_ACCESS_KEY_ID \
              -e AWS_SECRET_ACCESS_KEY \
              -e AWS_SESSION_TOKEN \
              -e AWS_DEFAULT_REGION="$AWS_REGION" \
              --entrypoint aws \
              public.ecr.aws/aws-cli/aws-cli:2.31.22 \
              ecr get-login-password --region "$AWS_REGION" \
              | docker login --username AWS --password-stdin "$ECR_REGISTRY"

            echo "=== ECR Docker registry authentication succeeded ==="
            docker logout "$ECR_REGISTRY" >/dev/null
          '''
        }
      }
    }
  }
}
