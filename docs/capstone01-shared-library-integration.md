# Capstone 01 — Shared Library pipeline integration candidate

## Status

**Not executed in Jenkins. No AWS/ECR/EKS change was made.** The original `Jenkinsfile` on `main` is intentionally unchanged. `Jenkinsfile.shared-library` is a separate candidate on `feat/capstone01-shared-library-pipeline`; configure a test Jenkins Pipeline job with **Script Path** `Jenkinsfile.shared-library` to evaluate it. Do not merge or replace the historical pipeline before reviewing this implementation.

## Source and library

- Application: this repository, originally created for the TWN bootcamp Jenkins/EKS exercise.
- Shared Library: [twn-devops-bootcamp-jenkins-shared-library](https://github.com/asambataiden/twn-devops-bootcamp-jenkins-shared-library), currently referenced at its **feature branch** for development. Pin a reviewed immutable library commit/tag before production.
- Library global Jenkins name: `twn-devops-bootcamp-jenkins-shared-library`; this must match Jenkins' configured Global Pipeline Library.
- Verify Jenkins runtime and plugin compatibility with the library Groovy implementation; Java 25 Gradle compilation alone is not Jenkins CPS compatibility.

## Required agent and Jenkins configuration

- Trusted Jenkins worker labeled `docker-aws-kubectl`, with Docker daemon, Maven installation named `maven-3.9`, appropriate Java 17+ JDK for this application's `pom.xml`, AWS CLI v2, and compatible `kubectl`.
- SCM credentials to check out this GitHub repository; Jenkins Pipeline Shared Library retrieval must also work.
- Trusted **short-lived** AWS identity on the agent (role federation/instance or workload identity) permitted to push to the specified immutable ECR repo and describe the intended EKS cluster. Avoid static AWS credentials in the Jenkinsfile.
- Kubernetes authentication for the same AWS identity, authorized with least-privilege RBAC in the target namespace. `eksDeployVerified` uses a temporary kubeconfig and doesn't rely on the agent's existing kubeconfig.
- Pre-existing ECR repository set to `IMMUTABLE`; pre-existing EKS cluster, namespace, Deployment and container (no infrastructure creation occurs).
- Configure GitHub branch trust restrictions: publishing is gated to `main`, the `PUBLISH_AND_DEPLOY` parameter and an explicit Jenkins approval step. Do not allow arbitrary untrusted PR code to run on privileged agents.

## Historical resource assumptions requiring verification

The old Jenkinsfile sets AWS account `591132357918`, region `eu-north-1`, and ECR repository `twn-devops-bootcamp/java-maven-app`. The candidate adopts those values as historical configuration, **not as proof they are currently active or authorized**.

The old Kubernetes manifest defines a Deployment/container `java-maven-app` and uses a runtime `APP_NAME` placeholder. The new pipeline assumes these resources already exist with that name, in `default`; inspect the real Deployment before enabling publishing. It no longer applies the old manifest's `aws-registry-key` imagePullSecret; ECR node image-pull permissions must be verified separately. Check actual cluster name, namespace and target resources.

The old Maven project uses Java 17 and Spring Boot 3.5.5; test and build compatibility and Dockerfile output must be confirmed before deployment. `mavenVerify` expects JUnit XML reports, so a repository without executable tests may fail that stage. Adding meaningful application tests is a quality gate rather than bypassing report publication.

## Safe evaluation order

1. Run application Maven tests and build in an isolated workspace and check that a valid JAR is produced.
2. Validate Jenkins Pipeline syntax and Shared Library resolution on a non-privileged test job; keep `PUBLISH_AND_DEPLOY=false`.
3. Check whether the Docker build succeeds, including the Java 17 Dockerfile and generated JAR.
4. Review the actual ECR repository/account and EKS Deployment/namespace/container with read-only credentials.
5. Configure limited, short-lived AWS access on a trusted agent; test failures first.
6. Run an authorized release from `main` with `PUBLISH_AND_DEPLOY=true` and an explicit `EKS_CLUSTER`; approve the prompt only after reviewing the target/image.
7. Capture source commit, Jenkins build URL, registry digest, Deployment rollout and application health as evidence. A successful rollout does not prove end-to-end application correctness.

## Security and release limitations

- A Git SHA-derived tag is immutable and will be refused by `ecrPush` on re-run if already pushed. Retry strategy needs separate release policy. A 12-character prefix is not a cryptographic uniqueness guarantee; ensure tag collision policy before production.
- The candidate intentionally has **no version bump commit, credential-bearing Git URL, push to main, blind `kubectl apply`, or automatic rollback**.
- A Jenkinsfile stored on a feature branch with access to a privileged agent is not automatically safe; use a restricted job and review the source before granting credentials.
- No automated pipeline-level tests or Jenkins execution have yet validated this candidate.
