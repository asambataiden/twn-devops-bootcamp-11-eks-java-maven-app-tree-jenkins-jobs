# Capstone 01 — Bootcamp Questions, Answers & What I Learned

> Learning journal for the TechWorld with Nana DevOps Bootcamp exercise: Java/Maven → Jenkins → Docker → Amazon ECR → Amazon EKS. Answers distinguish **verified observations** from **engineering recommendations**. These are study notes, not claims about undocumented course quiz answers.

## Project summary

**Question: What was the goal of this capstone?**

**Answer:** Automate building and testing a Java/Spring Boot application in Jenkins, package it into a Docker image, publish that artifact in Amazon ECR and deploy it using Kubernetes manifests on Amazon EKS. The repo additionally explores safe, digest-pinned releases and release validation.

**Question: What did I personally verify during portfolio hardening?**

**Answer:** Jenkins successfully compiled the app with Java 21, executed one passing JUnit test, built a Docker image, authenticated to AWS and ECR, published the image, and reported its SHA-256 digest. A separate AWS CLI query confirmed the same digest in ECR. Jenkins reached EKS and reported required namespace Deployment/Service permissions. Server-side validation accepted the two manifests. A new live rollout and HTTP verification were **not yet observed** in this hardening sequence.

## Architecture and workflow

**Q: Why use Jenkins, Maven, Docker, ECR and EKS together?**

**A:** Each tool has a responsibility: Maven compiles/tests; Jenkins orchestrates; Docker packages runtime dependencies; ECR distributes the image; EKS manages pods, desired state, health and rollout. Keeping these responsibilities separate makes failures easier to isolate.

**Q: What is the difference between CI and CD here?**

**A:** CI is build, test and image creation. Publishing to ECR prepares a deployable artifact. CD takes that verified artifact and changes Kubernetes resources. Separating them makes production changes deliberate and traceable.

**Q: Why use a dedicated namespace?**

**A:** `capstone-01` separates namespaced application resources from existing shared workloads, monitoring and other Bootcamp applications. Namespace isolation is organizational/RBAC-oriented; it is not by itself a strong security boundary.

**Q: Why two Deployment replicas and a ClusterIP Service?**

**A:** Two replicas demonstrate desired state and rolling deployment behavior. The internal Service gives stable service discovery and routes port 80 to the app’s port 8080 without creating a public AWS load balancer.

**Q: How are readiness and liveness different?**

**A:** Readiness removes an unready pod from Service endpoints; liveness can trigger container restart when health checks fail. This repository includes Spring Boot Actuator and enables probes at `/actuator/health/readiness` and `/actuator/health/liveness`. A deployed HTTP health response has not yet been captured.

## Build and container

**Q: Why run `mvn -B clean verify` in Jenkins?**

**A:** `clean` discards prior compiled outputs, `verify` executes the configured Maven lifecycle through verification, and `-B` selects non-interactive batch mode. In the recorded run, one JUnit test passed and the Spring Boot executable JAR was produced.

**Q: Why use Java 21 and a non-root image user?**

**A:** The Maven compiler targets Java 21 and the runtime image uses a Java 21 JRE. Running the application as UID 10001 avoids unnecessary root privileges inside the container. It is a defense-in-depth improvement, not complete isolation.

**Q: Why tag the image with application version and Jenkins build number?**

**A:** `1.1.11-15` relates the artifact to the Maven version and Jenkins build. The tag is useful for humans, while the SHA-256 digest is the content-addressed identity. For rollouts, digest-pinning avoids mutable-tag ambiguity.

**Q: What exactly was published?**

**A:** The ECR image `twn-devops-bootcamp/java-maven-app:1.1.11-15`, digest `sha256:1115e05dc7d3e64a5d2439b8c7e3d6325697334a39220b3167ff2a652ad8c5e7`, confirmed independently by Jenkins output and AWS ECR describe-images on October 25, 2026.

## AWS, Kubernetes and troubleshooting

**Q: Why was the AWS CLI run as a container?**

**A:** The Jenkins agent had Docker but did not have an AWS CLI executable installed. Using a pinned public ECR AWS CLI image supported AWS identity, ECR and EKS API calls without changing the base Jenkins installation. A maintained Jenkins agent image would reduce runtime dependencies on Docker-in-Docker-style invocations.

**Q: Why was a version-matched kubectl important?**

**A:** The cluster was EKS 1.34 while the Jenkins executable was 1.31. The test used containerized `kubectl v1.34.1` instead of assuming a significantly older client would be supported.

**Q: Why did kubectl first connect to localhost:8080?**

**A:** A temporary kubeconfig was created in the Jenkins container but not accessible at the bind-mounted path expected by a sibling Docker container. Without the intended config, kubectl tried its default endpoint. The read-only RBAC test succeeded after supplying kubeconfig via stdin.

**Q: What does a successful `kubectl auth can-i create deployments` prove?**

**A:** It confirms Kubernetes authorization for that verb and resource under the current credentials. It does not prove an application was deployed, the nodes can pull the image or the application is healthy.

**Q: Why check the AWS account and ECR digest before release?**

**A:** Account verification reduces cross-account mistakes; digest validation ensures the release script references the previously published artifact, rather than an unverified mutable tag.

**Q: Why use `kubectl apply --dry-run=server`?**

**A:** It asks the real API server to validate a prospective operation without persisting objects. The observed messages saying `created (server dry run)` were validation results, not evidence that the resources exist.

**Q: Why did the first controlled deployment pipeline fail after dry run?**

**A:** Jenkins had not supplied the new `APPLY_DEPLOYMENT` parameter on its initial run. Because the script used `set -u`, reading that unset variable produced an error. The guard was changed to `${APPLY_DEPLOYMENT:-false}` so an absent value defaults to no deployment. The corrected pipeline has not been rerun in the supplied evidence.

**Q: Why avoid modifying the existing Bootcamp cluster unnecessarily?**

**A:** The cluster hosts other projects and monitoring components. Restricting changes to the designated namespace and using dry runs prevents accidental disruption and unnecessary infrastructure duplication or costs.

## What I learned

1. **Build evidence is stronger than a configuration screenshot.** Jenkins logs and the exact ECR digest prove that tested source produced and published a real artifact.
2. **Identity, authentication and authorization are separate checkpoints.** AWS STS identity, EKS token generation and Kubernetes RBAC required distinct checks.
3. **Container boundaries affect paths and credentials.** A kubeconfig available in Jenkins may not exist at the same location for a Docker sibling container.
4. **Fail-safe defaults matter.** An unset deployment parameter should preserve a dry run, not accidentally change infrastructure.
5. **Immutable releases improve reproducibility.** Use tags for discoverability and digests for exact deployment provenance.
6. **A successful dry run is not a successful rollout.** Kubernetes admission, image pulling, scheduling, probes and application HTTP behavior are separate validations.
7. **Cloud security is an ongoing engineering concern.** The exercise used an existing administrative AWS identity for Jenkins; a dedicated least-privilege role is the preferred production design.
8. **Professional documentation should report the limits of verification.** State what was demonstrated and leave pending evidence clearly marked instead of exaggerating the project’s state.
9. **Avoid repeating work without a learning or validation benefit.** Once an exercise and its evidence are complete, prioritize explaining design, trade-offs, troubleshooting and operational improvements for the portfolio.

## Improvements I would make for production

- Use a dedicated IAM role with scoped ECR permissions and namespace-restricted EKS authorizations, ideally short-lived credentials instead of a long-lived IAM access key.
- Use a dedicated, hardened Jenkins agent rather than building and deploying on the controller.
- Add image scanning, dependency checks, software bill of materials (SBOM), digest promotion and image provenance.
- Apply resource quotas/network policies and assess runtime permissions based on actual workload requirements.
- Use separate promotion approval, post-deploy smoke tests, rollout observability and an explicit rollback procedure.
- Keep cloud resources reproducible with infrastructure-as-code and document cleanup responsibilities.

## Reflection prompts for the portfolio review

- Explain why an ECR push can succeed when an EKS deployment would fail.
- Identify which credentials Jenkins needs for registry publishing versus Kubernetes API access.
- Show how you can verify both the published artifact and a running workload.
- Describe the difference between the original Bootcamp exercise and the security/release hardening completed afterward.

## Related files

- [Repository overview](../README.md)
- [Jenkins ECR publishing pipeline](../jenkins/build-push-ecr.Jenkinsfile)
- [Controlled Kubernetes deployment pipeline](../jenkins/deploy-ecr-digest-eks.Jenkinsfile)
- [Kubernetes Deployment](../kubernetes/deployment.yaml)
- [Kubernetes Service](../kubernetes/service.yaml)

**Attribution:** Derived from the TechWorld with Nana Bootcamp project, repository implementation and verified execution logs. The explanations and recommendations are additional engineering reflection.
