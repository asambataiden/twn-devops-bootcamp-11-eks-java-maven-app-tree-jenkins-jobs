# Capstone 01 – CI/CD with Jenkins, Amazon ECR and Amazon EKS

> Work in progress — this is a hardened continuation of the TechWorld with Nana DevOps Bootcamp Module 11 exercise. **End-to-end execution has not yet been revalidated.**

## Goal

Build and test a Java/Maven application in Jenkins, build and push its container image to Amazon ECR, then deploy it to Amazon EKS with Kubernetes manifests.

## Architecture

GitHub → Jenkins (Maven verify + Docker build) → Amazon ECR → Amazon EKS (Deployment + Service) → rollout validation.

## Existing implementation

- Spring Boot Java 17 application and Maven build
- Declarative `Jenkinsfile` with build, image, push, deployment, and rollout stages
- Multi-replica Kubernetes Deployment and internal Service in `kubernetes/`
- Runtime Docker image with fixed entrypoint and non-root UID

## Prerequisites

- Jenkins agent: Java 17, Maven tool named `maven-3.9`, Docker, AWS CLI, `kubectl`, and `envsubst`
- Jenkins AWS Credentials plugin and a credentials entry with ID `aws-jenkins-capstone-01`
- ECR repository `twn-devops-bootcamp/java-maven-app` in the configured AWS region/account
- An EKS cluster with sufficient worker capacity and an IAM principal authorized for Kubernetes deployment
- Appropriate ECR image-pull permissions on the worker node IAM role (or equivalent pod pull mechanism)
- Kubernetes namespace configured in `K8S_NAMESPACE` (currently defaults to `default`)

**Configuration:** Set `EKS_CLUSTER_NAME` to the actual cluster name before running. Confirm `AWS_ACCOUNT_ID`, `AWS_REGION`, `ECR_REPOSITORY`, and the AWS credentials ID. Never commit credentials, kubeconfigs, or access tokens.

## Local container validation

After a successful `mvn -B clean verify`, build a local image using the capstone naming convention:

```bash
docker build -t twn-capstone-01-eks-ecr-cicd:1.1.11-local .
docker run --rm --name twn-capstone-01-app -p 127.0.0.1:8080:8080 twn-capstone-01-eks-ecr-cicd:1.1.11-local
```

In a second terminal, test a known application endpoint with `curl -i http://127.0.0.1:8080/`. If the root endpoint does not exist, inspect the application's controller mappings before choosing a health check. Stop the foreground container with Ctrl+C.

The local image name is separate from the current ECR registry/repository configuration in `Jenkinsfile`. Any future ECR repository rename must be made together with AWS provisioning and IAM verification.

## Deployment and verification

1. Review the pipeline and IAM permissions for the chosen AWS account.
2. Run Jenkins using this branch; confirm `mvn -B clean verify`, the ECR image push, and Kubernetes rollout.
3. Inspect the application using these commands with appropriate kubeconfig/context:

```bash
kubectl config current-context
kubectl -n default get deployments,pods,services
kubectl -n default rollout status deployment/java-maven-app --timeout=180s
kubectl -n default describe deployment java-maven-app
```

4. Verify HTTP behavior independently; a successful rollout alone does not establish application functionality. For an internal Service, use a temporary port-forward, then test an application endpoint:

```bash
kubectl -n default port-forward service/java-maven-app 8080:80
# In another terminal, curl an endpoint actually implemented by this application.
```

5. Save sanitized Jenkins console logs, image tag/digest, rollout output, and HTTP response evidence in your project documentation.

## Security and operational notes

- AWS access is handled through Jenkins credential binding; configure narrowly scoped permissions.
- ECR authentication uses `aws ecr get-login-password`, not a stored Docker password.
- Kubernetes probes currently use TCP connections; replace them with HTTP readiness/liveness endpoints when the application exposes suitable endpoints.
- CPU/memory settings are learning-project defaults, not production sizing.
- The image tag includes the Maven project version and Jenkins build number; prefer immutable digests for production deployments.
- The pipeline does not automatically create AWS infrastructure or grant EKS IAM access.

## Cleanup

Delete application resources only when they are no longer required:

```bash
kubectl -n default delete service java-maven-app --ignore-not-found
kubectl -n default delete deployment java-maven-app --ignore-not-found
```

Remove ECR images and delete any temporary EKS/cloud infrastructure separately, after checking whether other applications depend on those resources.

## Validation status

- [x] Existing source, Jenkinsfile, Dockerfile and manifests reviewed
- [x] Pipeline, runtime image and manifest improvements committed on a feature branch
- [ ] Jenkins agent and AWS credential prerequisites verified
- [ ] Maven build and container build executed on current branch
- [ ] ECR push and EKS rollout executed successfully
- [ ] Application HTTP response verified
- [ ] Final TWN submission description, evidence and secure publication review completed

## Source attribution

Based on TechWorld with Nana's DevOps Bootcamp exercises, extended with independent pipeline hardening, deployment checks and documentation. See the commit history and feature branch for changes.
