# Capstone 01 — Jenkins → Amazon ECR → Amazon EKS

> TechWorld with Nana DevOps Bootcamp, Module 11. This repository includes the Bootcamp implementation and subsequent portfolio-focused validation and pipeline hardening. **CI, ECR publishing, EKS access and server-side manifest validation are verified. A new end-to-end EKS rollout from the hardened pipeline has not been evidenced.**

## Objective

Build and test a Java/Spring Boot application, package it as a container, publish a versioned image to Amazon ECR and deploy that image to Amazon EKS using Jenkins and Kubernetes manifests.

## Architecture

```text
GitHub (feature branch)
       │
       ▼
Jenkins (Java 21 + Maven 3.9)
       │
       ├── mvn -B clean verify → JUnit results
       ├── Docker image build (non-root runtime)
       │
       ▼
Amazon ECR (eu-north-1)
       │  image tag + SHA-256 digest
       ▼
Amazon EKS 1.34
       │
       └── namespace: capstone-01
           ├── Deployment (2 replicas, HTTP health probes)
           └── ClusterIP Service (80 → 8080)
```

Cloud resources shown here are shared existing infrastructure, not created by these pipelines. The EKS deployment to `capstone-01` is a planned/validated target, not a newly verified live rollout.

## Technology stack

Java 21, Spring Boot 3.5.5, Maven, JUnit 5, Docker, Jenkins Declarative Pipeline, AWS CLI 2.31.22 (containerized), Amazon ECR, Amazon EKS 1.34, kubectl 1.34.1 (containerized), Kubernetes, and `envsubst`.

## Repository layout

| Path | Purpose |
| --- | --- |
| `pom.xml`, `src/` | Java application, dependencies and tests |
| `Dockerfile` | Java 21 runtime image; runs as UID 10001 |
| `Jenkinsfile` | Original integrated pipeline; **do not use unchanged for the hardened workflow** |
| `jenkins/build-only.Jenkinsfile` | Build, test and container validation |
| `jenkins/build-push-ecr.Jenkinsfile` | Successful Maven → Docker → ECR publishing |
| `jenkins/deploy-ecr-digest-eks.Jenkinsfile` | Opt-in EKS deploy with dry-run default; successful dry-run not yet recorded for its latest revision |
| `jenkins/validate-*.Jenkinsfile` | Incremental AWS/EKS/ECR troubleshooting and access evidence |
| `kubernetes/namespace.yaml` | Dedicated `capstone-01` namespace |
| `kubernetes/deployment.yaml` | 2-replica Deployment with health probes/resource limits |
| `kubernetes/service.yaml` | Internal ClusterIP Service |
| `docs/BOOTCAMP-QA-AND-LEARNINGS.md` | Decisions, questions/answers, lessons and next improvements |

## Verified execution evidence (October 25, 2026)

| Area | Observed evidence | Result |
| --- | --- | --- |
| Java build and tests | `mvn -B clean verify`, one JUnit test, no failures | PASS |
| Docker build | Build of `java-maven-app:1.1.11-15` | PASS |
| Jenkins AWS identity | Correct account `591132357918` | PASS |
| ECR repository | `twn-devops-bootcamp/java-maven-app` exists | PASS |
| EKS cluster | `floral-mongoose-1792497995` ACTIVE | PASS |
| Kubernetes access | Jenkins can reach `capstone-01` and reports allowed get/list/create/patch operations | PASS |
| ECR Docker login | `Login Succeeded` | PASS |
| ECR publish | Tag `1.1.11-15` and matching digest confirmed by Jenkins and a separate AWS CLI query | PASS |
| Deployment and Service schemas | Both accepted by `kubectl apply --dry-run=server` on EKS | PASS |
| New deployment rollout in `capstone-01` | No completed rollout/pod readiness/HTTP check recorded in current hardening evidence | NOT VERIFIED |

**Published image reference:**

```text
591132357918.dkr.ecr.eu-north-1.amazonaws.com/twn-devops-bootcamp/java-maven-app@sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7
```

Use the digest to pin the tested artifact; a mutable tag alone is insufficient to establish image identity.

## Reproduce the verified CI/publish step

Jenkins job `twn-capstone-01-eks-ecr-cicd` uses **Pipeline script from SCM**, branch `*/feat/cap01-pipeline-hardening`.

- Set Script Path to `jenkins/build-push-ecr.Jenkinsfile`.
- Ensure the `maven-3.9` Jenkins tool, Java 21, Docker, and `aws-jenkins-capstone-01` credential are configured.
- Run the build to execute tests, build the Docker image and push it to the existing ECR repository.
- Publishing writes to ECR and can incur storage charges. Each Jenkins run creates a build-numbered image tag.

For validation without publishing, select `jenkins/build-only.Jenkinsfile` instead.

## EKS manifest validation (read-only in effect)

After setting AWS CLI credentials and kubeconfig for the *correct* AWS account and cluster:

```bash
export APP_NAME=java-maven-app
export IMAGE_URI='591132357918.dkr.ecr.eu-north-1.amazonaws.com/twn-devops-bootcamp/java-maven-app@sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7'
envsubst '${APP_NAME} ${IMAGE_URI}' < kubernetes/deployment.yaml > /tmp/cap01-deployment.yaml
envsubst '${APP_NAME}' < kubernetes/service.yaml > /tmp/cap01-service.yaml
kubectl -n capstone-01 apply --dry-run=server -f /tmp/cap01-deployment.yaml -f /tmp/cap01-service.yaml
```

The successful dry-run outputs were `deployment.apps/java-maven-app created (server dry run)` and `service/java-maven-app created (server dry run)`. The word `created` here does **not** indicate resources were persisted.

**Optional deployment:** `jenkins/deploy-ecr-digest-eks.Jenkinsfile` defaults `APPLY_DEPLOYMENT=false` and only applies changes with an explicit true value. Its first observed Jenkins run passed server validation but failed because the parameter was absent; commit `8984fdf` made the missing value default to false. A successful rerun and actual rollout are not recorded.

## Verify a live deployment, if performed later

```bash
kubectl -n capstone-01 get deployments,pods,services
kubectl -n capstone-01 rollout status deployment/java-maven-app --timeout=300s
kubectl -n capstone-01 port-forward service/java-maven-app 8080:80
# Separate terminal:
curl -fsS http://127.0.0.1:8080/actuator/health/readiness
```

Do not claim successful rollout solely from ECR publication or dry-run results. Keep verified HTTP responses and rollout logs as evidence.

## Security, operational notes and trade-offs

- Secrets are bound from Jenkins credentials. Authentication tokens and temporary kubeconfigs must not be checked into Git.
- The Jenkins EKS access test used an existing administrative AWS principal; introduce a dedicated least-privilege role for production.
- The container runs with a non-root UID. The Deployment declares CPU/memory requests and limits, and Spring Boot Actuator HTTP readiness/liveness endpoints.
- `ClusterIP` avoids provisioning an additional external load balancer for this exercise.
- AWS CLI and kubectl run in version-pinned containers because the Jenkins agent did not have AWS CLI installed and its kubectl was behind the EKS server version.
- Containerized kubectl initially failed to locate a mounted kubeconfig and defaulted to `localhost:8080`; streaming credentials over stdin resolved read-only RBAC validation.
- Consider automated vulnerability scans, immutable repository tags, digest promotion, image provenance/SBOM, explicit promotion approvals and rollback automation as subsequent improvements.
- ECR artifacts, running EKS nodes, and other shared AWS resources can incur costs. Do not delete shared cluster components.

## Cleanup (only if this app was deployed)

```bash
kubectl -n capstone-01 delete service java-maven-app --ignore-not-found
kubectl -n capstone-01 delete deployment java-maven-app --ignore-not-found
```

Do not remove `capstone-01`, the EKS cluster, shared monitoring, or the ECR repository without a separate ownership/dependency review.

## Learning journal and attribution

See [Bootcamp Q&A and What I Learned](docs/BOOTCAMP-QA-AND-LEARNINGS.md).

Based on the TechWorld with Nana DevOps Bootcamp learning exercise, independently extended for portfolio documentation, safer release controls, and troubleshooting. Original course work and later verification/hardening are intentionally distinguished.
