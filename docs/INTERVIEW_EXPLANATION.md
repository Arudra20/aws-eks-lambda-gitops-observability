# Interview explanation

## Project summary

In this project, I designed an AWS cloud-native deployment platform where infrastructure is provisioned using Terraform, application delivery is automated through GitHub Actions, and Kubernetes deployment is controlled through GitOps using Argo CD and Helm.

The application is a containerized order API running on Amazon EKS. It exposes health, readiness, and metrics endpoints and integrates with AWS Lambda using IRSA. The Lambda function acts as a serverless order processor. The application is exposed externally using AWS Load Balancer Controller and ALB Ingress.

## End-to-end flow

Developer commits code to GitHub. GitHub Actions builds the Docker image, scans/builds it, pushes the image to Amazon ECR, and updates the Helm values file with the new immutable image tag. Since Git is the source of truth, Argo CD detects the Git change and syncs the Helm release to EKS. Kubernetes performs a rolling update with readiness probes and zero downtime behavior.

## Why Helm

We used Helm because it allows reusable Kubernetes templates, environment-specific values, versioned releases, rollback, and standardized deployment configuration across environments.

## Why Argo CD

We used Argo CD to implement GitOps. Instead of CI directly applying manifests to the cluster, Argo CD continuously reconciles the desired state from Git with the actual state in Kubernetes. This gives better auditability, drift detection, self-healing, and safer rollback.

## Why IRSA

The EKS pod needs to invoke AWS Lambda. Instead of storing AWS access keys in Kubernetes secrets, we used IAM Roles for Service Accounts. The service account is mapped to an IAM role that only allows `lambda:InvokeFunction` on the required Lambda function.

## Why Dynatrace

Dynatrace gives Kubernetes workload visibility, pod/node health, infrastructure metrics, logs/events, traces, service topology, and automatic problem detection. For first-time setup, Dynatrace Operator and DynaKube are used to onboard the EKS cluster.
