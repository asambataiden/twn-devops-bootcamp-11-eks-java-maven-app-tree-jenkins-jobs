pipeline {
  agent any
  tools {
    maven 'maven-3.9'
  }
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = 'eu-north-1'
    AWS_ACCOUNT_ID = '591132357918'
    ECR_REPOSITORY = 'twn-devops-bootcamp/java-maven-app'
    EKS_CLUSTER_NAME = 'REPLACE_WITH_YOUR_EKS_CLUSTER_NAME'
    APP_NAME = 'java-maven-app'
    K8S_NAMESPACE = 'default'
  }
  stages {
    stage('Build and test') {
      steps {
        sh 'mvn -B clean verify'
        script {
          env.APP_VERSION = sh(script: 'mvn -q -DforceStdout help:evaluate -Dexpression=project.version | tail -n 1', returnStdout: true).trim()
          env.IMAGE_TAG = "${env.APP_VERSION}-${env.BUILD_NUMBER}"
          env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"
          env.IMAGE_URI = "${env.ECR_REGISTRY}/${env.ECR_REPOSITORY}:${env.IMAGE_TAG}"
        }
      }
    }
    stage('Build container') {
      steps { sh 'docker build --tag "$IMAGE_URI" .' }
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
            set -eu
            aws ecr get-login-password --region "$AWS_REGION" |
              docker login --username AWS --password-stdin "$ECR_REGISTRY"
            docker push "$IMAGE_URI"
            docker logout "$ECR_REGISTRY"
          '''
        }
      }
    }
    stage('Deploy to EKS') {
      steps {
        withCredentials([[
          $class: 'AmazonWebServicesCredentialsBinding',
          credentialsId: 'aws-jenkins-capstone-01',
          accessKeyVariable: 'AWS_ACCESS_KEY_ID',
          secretKeyVariable: 'AWS_SECRET_ACCESS_KEY'
        ]]) {
          sh '''
            set -eu
            test "$EKS_CLUSTER_NAME" != REPLACE_WITH_YOUR_EKS_CLUSTER_NAME
            export KUBECONFIG="$(mktemp)"
            trap 'rm -f "$KUBECONFIG"' EXIT
            aws eks update-kubeconfig --region "$AWS_REGION" --name "$EKS_CLUSTER_NAME" --kubeconfig "$KUBECONFIG"
            export APP_NAME IMAGE_URI
            envsubst < kubernetes/deployment.yaml | kubectl -n "$K8S_NAMESPACE" apply -f -
            envsubst < kubernetes/service.yaml | kubectl -n "$K8S_NAMESPACE" apply -f -
            kubectl -n "$K8S_NAMESPACE" rollout status deployment/"$APP_NAME" --timeout=180s
          '''
        }
      }
    }
  }
  post {
    always { archiveArtifacts artifacts: 'target/surefire-reports/*.xml', allowEmptyArchive: true }
  }
}
