pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  parameters {
    booleanParam(name: 'APPLY_DEPLOYMENT', defaultValue: false,
      description: 'Check to deploy; unchecked runs a server-side dry run only')
  }
  environment {
    AWS_REGION = 'eu-north-1'
    EKS_CLUSTER_NAME = 'floral-mongoose-1792497995'
    K8S_NAMESPACE = 'capstone-01'
    APP_NAME = 'java-maven-app'
    IMAGE_URI = '591132357918.dkr.ecr.eu-north-1.amazonaws.com/twn-devops-bootcamp/java-maven-app@sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7'
  }
  stages {
    stage('Validate or deploy image to EKS') {
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
            umask 077
            tmpdir="$(mktemp -d)"
            container_id=""
            cleanup() {
              if [ -n "$container_id" ]; then docker rm -f "$container_id" >/dev/null 2>&1 || true; fi
              rm -rf "$tmpdir"
            }
            trap cleanup EXIT

            aws_cli() {
              docker run --rm -e AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY \
                -e AWS_SESSION_TOKEN -e AWS_DEFAULT_REGION="$AWS_REGION" \
                --entrypoint aws public.ecr.aws/aws-cli/aws-cli:2.31.22 "$@"
            }
            account="$(aws_cli sts get-caller-identity --query Account --output text)"
            test "$account" = "591132357918"
            digest="$(aws_cli ecr describe-images \
              --repository-name twn-devops-bootcamp/java-maven-app \
              --image-ids imageDigest=sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7 \
              --query 'imageDetails[0].imageDigest' --output text)"
            test "$digest" = "sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7"

            export APP_NAME IMAGE_URI
            envsubst < kubernetes/deployment.yaml > "$tmpdir/deployment.yaml"
            envsubst < kubernetes/service.yaml > "$tmpdir/service.yaml"
            grep -F "$IMAGE_URI" "$tmpdir/deployment.yaml" >/dev/null

            endpoint="$(aws_cli eks describe-cluster --name "$EKS_CLUSTER_NAME" --query cluster.endpoint --output text)"
            ca_data="$(aws_cli eks describe-cluster --name "$EKS_CLUSTER_NAME" --query cluster.certificateAuthority.data --output text)"
            token="$(aws_cli eks get-token --cluster-name "$EKS_CLUSTER_NAME" --query status.token --output text)"
            printf 'apiVersion: v1\\nkind: Config\\nclusters:\\n- name: target\\n  cluster:\\n    server: %s\\n    certificate-authority-data: %s\\nusers:\\n- name: jenkins\\n  user:\\n    token: %s\\ncontexts:\\n- name: target\\n  context:\\n    cluster: target\\n    user: jenkins\\n    namespace: %s\\ncurrent-context: target\\n' \
              "$endpoint" "$ca_data" "$token" "$K8S_NAMESPACE" > "$tmpdir/config"
            unset token

            kube() {
              container_id="$(docker create --entrypoint kubectl registry.k8s.io/kubectl:v1.34.1 \
                --kubeconfig=/tmp/config "$@")"
              docker cp "$tmpdir/config" "$container_id:/tmp/config"
              docker cp "$tmpdir/deployment.yaml" "$container_id:/tmp/deployment.yaml"
              docker cp "$tmpdir/service.yaml" "$container_id:/tmp/service.yaml"
              docker start -a "$container_id"
              rc="$(docker inspect --format '{{.State.ExitCode}}' "$container_id")"
              docker rm "$container_id" >/dev/null
              container_id=""
              test "$rc" -eq 0
            }
            echo "=== Server-side manifest dry run ==="
            kube -n "$K8S_NAMESPACE" apply --dry-run=server \
              -f /tmp/deployment.yaml -f /tmp/service.yaml
            if [ "${APPLY_DEPLOYMENT:-false}" != "true" ]; then
              echo "Dry run passed; deployment disabled by default."
              exit 0
            fi
            echo "=== Deploy in capstone-01 ==="
            kube -n "$K8S_NAMESPACE" apply -f /tmp/deployment.yaml -f /tmp/service.yaml
            kube -n "$K8S_NAMESPACE" rollout status deployment/"$APP_NAME" --timeout=300s
            kube -n "$K8S_NAMESPACE" get deployment "$APP_NAME" -o jsonpath='{.spec.template.spec.containers[0].image}'
            echo
          '''
        }
      }
    }
  }
}
