pipeline {
  agent any
  tools { maven 'maven-3.9' }
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = 'eu-north-1'
    ECR_REGISTRY = '591132357918.dkr.ecr.eu-north-1.amazonaws.com'
    ECR_REPOSITORY = 'twn-devops-bootcamp/java-maven-app'
  }
  stages {
    stage('Build and test') {
      steps {
        sh 'mvn -B clean verify'
        script {
          env.APP_VERSION = sh(script: 'mvn -q -DforceStdout help:evaluate -Dexpression=project.version | tail -n 1', returnStdout: true).trim()
          if (!(env.APP_VERSION ==~ /[0-9A-Za-z][0-9A-Za-z_.-]*/)) {
            error 'Invalid Maven project version for Docker image tag'
          }
          env.IMAGE_TAG = "${env.APP_VERSION}-${env.BUILD_NUMBER}"
          env.IMAGE_URI = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
        }
      }
      post {
        always { junit testResults: 'target/surefire-reports/*.xml', allowEmptyResults: true }
      }
    }
    stage('Build Docker image') {
      steps {
        sh '''
          set -eu
          docker build --tag "$IMAGE_URI" .
          docker image inspect "$IMAGE_URI" --format '{{.Id}}'
        '''
      }
    }
    stage('Push image to ECR') {
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
            trap 'docker logout "$ECR_REGISTRY" >/dev/null 2>&1 || true; rm -rf "$DOCKER_CONFIG"' EXIT
            docker run --rm \
              -e AWS_ACCESS_KEY_ID \
              -e AWS_SECRET_ACCESS_KEY \
              -e AWS_SESSION_TOKEN \
              -e AWS_DEFAULT_REGION="$AWS_REGION" \
              --entrypoint aws \
              public.ecr.aws/aws-cli/aws-cli:2.31.22 \
              ecr get-login-password --region "$AWS_REGION" \
              | docker login --username AWS --password-stdin "$ECR_REGISTRY"
            docker push "$IMAGE_URI"
            echo "Published image: $IMAGE_URI"
          '''
        }
      }
    }
  }
}
