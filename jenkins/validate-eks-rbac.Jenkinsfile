pipeline {
  agent any
  options { timestamps(); disableConcurrentBuilds() }
  environment {
    AWS_REGION = 'eu-north-1'
    EKS_CLUSTER_NAME = 'floral-mongoose-1792497995'
    K8S_NAMESPACE = 'capstone-01'
  }
  stages {
    stage('Validate Jenkins Kubernetes access (read-only)') {
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
            export AWS_PAGER=""

            tmp_dir="$(mktemp -d)"
            chmod 700 "$tmp_dir"
            trap 'rm -rf "$tmp_dir"' EXIT

            aws_cli() {
              docker run --rm \
                -e AWS_ACCESS_KEY_ID \
                -e AWS_SECRET_ACCESS_KEY \
                -e AWS_SESSION_TOKEN \
                -e AWS_DEFAULT_REGION="$AWS_REGION" \
                --entrypoint aws \
                public.ecr.aws/aws-cli/aws-cli:2.31.22 "$@"
            }

            echo "=== Obtain EKS API endpoint, CA and short-lived auth token ==="
            endpoint="$(aws_cli eks describe-cluster --name "$EKS_CLUSTER_NAME" --query cluster.endpoint --output text)"
            ca_data="$(aws_cli eks describe-cluster --name "$EKS_CLUSTER_NAME" --query cluster.certificateAuthority.data --output text)"
            token="$(aws_cli eks get-token --cluster-name "$EKS_CLUSTER_NAME" --query status.token --output text)"
            test -n "$endpoint" && test -n "$ca_data" && test -n "$token"

            # Keep the short-lived token in a private, temporary kubeconfig.
            umask 077
            printf 'apiVersion: v1\nkind: Config\nclusters:\n- name: target\n  cluster:\n    server: %s\n    certificate-authority-data: %s\nusers:\n- name: jenkins\n  user:\n    token: %s\ncontexts:\n- name: target\n  context:\n    cluster: target\n    user: jenkins\n    namespace: %s\ncurrent-context: target\n' \
              "$endpoint" "$ca_data" "$token" "$K8S_NAMESPACE" > "$tmp_dir/config"
            unset token

            kube() {
              docker run --rm \
                --user "$(id -u):$(id -g)" \
                -v "$tmp_dir:/kube:ro" \
                -e KUBECONFIG=/kube/config \
                --entrypoint kubectl \
                registry.k8s.io/kubectl:v1.34.1 "$@"
            }

            echo "=== kubectl version ==="
            kube version --client
            echo "=== Verify namespace exists and is accessible ==="
            kube get namespace "$K8S_NAMESPACE"
            echo "=== Read-only Kubernetes authorization checks ==="
            for permission in 'get deployments' 'list deployments' 'create deployments' 'patch deployments' 'get services' 'create services' 'patch services'; do
              set -- $permission
              echo "Can Jenkins $1 $2 in $K8S_NAMESPACE?"
              kube auth can-i "$1" "$2" --namespace "$K8S_NAMESPACE"
            done
            echo "=== Kubernetes connectivity validation complete (permissions reported above) ==="
          '''
        }
      }
    }
  }
}
