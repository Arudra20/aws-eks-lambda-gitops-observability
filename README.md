# EKS + Lambda + GitHub Actions + Helm + Argo CD + Dynatrace Observability

This repository is a complete reference project for deploying a containerized API on **Amazon EKS**, integrating it with **AWS Lambda**, deploying with **Helm**, promoting through **GitOps using Argo CD**, provisioning AWS infrastructure with **Terraform**, and monitoring the platform with **Dynatrace free trial**.

## What this project builds

| Layer | Component |
|---|---|
| Cloud | AWS VPC, public/private subnets, NAT Gateway, EKS, managed node group, ECR, Lambda |
| App | Python Flask order API deployed on EKS |
| Serverless | AWS Lambda order processor invoked from the EKS app |
| Deployment | GitHub Actions builds Docker image and updates Helm image tag |
| GitOps | Argo CD watches Git and syncs Helm chart to EKS |
| Exposure | AWS Load Balancer Controller + ALB Ingress |
| Monitoring | Dynatrace Operator + DynaKube for Kubernetes observability |
| Optional OSS Monitoring | Prometheus/Grafana values included |

## Naming convention

Default convention:

```text
<project>-<environment>-<component>
```

Example:

```text
ekslambda-dev-eks
ekslambda-dev-vpc
ekslambda-dev-order-api
ekslambda-dev-order-processor
ekslambda-dev-gha-deploy-role
```

See `docs/NAMING_CONVENTION.md`.

## Repository structure

```text
.
├── app/order-api/                  # Flask API running on EKS
├── lambda/order-processor/         # AWS Lambda function source
├── helm/order-api/                 # Helm chart for app deployment
├── gitops/argocd/                  # Argo CD Application manifest
├── infra/terraform/                # Terraform infra modules and dev env
├── platform/dynatrace/             # Dynatrace DynaKube manifest template
├── platform/monitoring/            # Optional kube-prometheus-stack values
├── scripts/powershell/             # Windows PowerShell commands
├── .github/workflows/              # GitHub Actions workflows
└── docs/                           # Step-by-step guides
```

## Fast execution order

1. Edit `infra/terraform/envs/dev/terraform.tfvars`.
2. Bootstrap Terraform backend.
3. Apply Terraform infra.
4. Update kubeconfig.
5. Install AWS Load Balancer Controller.
6. Install Argo CD.
7. Create GitHub repo variables.
8. Push code to GitHub.
9. GitHub Actions builds image and updates Helm tag.
10. Apply Argo CD Application.
11. Install Dynatrace Operator and apply DynaKube.
12. Validate app, ALB, Argo CD, pods, Lambda invocation, and Dynatrace dashboards.

Full guide: `docs/STEP_BY_STEP.md`.

## Important first-time note

This project is intentionally written as a learning + portfolio project. For company production, split infra repo and app GitOps repo, pin chart/operator versions, add branch protection, secrets scanning, policy-as-code, SSO for Argo CD, and least-privilege IAM.
