<!-- Badges -->
<p align="left">
  <img src="https://img.shields.io/badge/Terraform-1.x-7B42BC?style=flat&logo=terraform&logoColor=white"/>
  <img src="https://img.shields.io/badge/AWS-EKS-FF9900?style=flat&logo=amazonaws&logoColor=white"/>
  <img src="https://img.shields.io/badge/AWS-Lambda-FF9900?style=flat&logo=awslambda&logoColor=white"/>
  <img src="https://img.shields.io/badge/GitHub_Actions-2088FF?style=flat&logo=githubactions&logoColor=white"/>
  <img src="https://img.shields.io/badge/Helm-3.x-0F1689?style=flat&logo=helm&logoColor=white"/>
  <img src="https://img.shields.io/badge/Argo_CD-GitOps-EF7B4D?style=flat&logo=argo&logoColor=white"/>
  <img src="https://img.shields.io/badge/Dynatrace-Observability-1496FF?style=flat&logo=dynatrace&logoColor=white"/>
  <img src="https://img.shields.io/badge/Python-Flask-3776AB?style=flat&logo=python&logoColor=white"/>
  <img src="https://img.shields.io/badge/License-MIT-green?style=flat"/>
</p>

# EKS + Lambda + GitOps + Dynatrace — Reference Platform

A complete, end-to-end reference project for deploying a containerised Python Flask API on **Amazon EKS**, integrating with **AWS Lambda**, automating image delivery via **GitHub Actions**, promoting through **GitOps with Argo CD**, provisioning all AWS infrastructure with **Terraform**, and observing the full platform with **Dynatrace**.

This project is intentionally built as a **learning and portfolio reference** — every layer is explained, every decision is documented, and every component can be understood in isolation or as part of the whole.

---

## What this project builds

| Layer | Component | Tech |
|---|---|---|
| **Cloud infrastructure** | VPC, subnets, NAT Gateway, EKS cluster, managed node group, ECR, Lambda | Terraform |
| **Application** | Python Flask order API running on EKS | Docker, Flask |
| **Serverless** | Order processor Lambda invoked from the EKS app | AWS Lambda, Python |
| **CI/CD** | Image build, push to ECR, Helm values update | GitHub Actions |
| **GitOps** | Argo CD watches Git and reconciles Helm chart to EKS | Argo CD |
| **Ingress** | ALB created from Kubernetes Ingress resource | AWS Load Balancer Controller |
| **Observability** | Full Kubernetes + app observability | Dynatrace Operator + DynaKube |
| **Alt. observability** | Optional open-source monitoring stack | Prometheus + Grafana |

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         Developer Workflow                                  │
│                                                                             │
│   git push → GitHub Actions CI/CD                                           │
│              │                                                              │
│              ├─► Docker build → Trivy scan → Push image to ECR              │
│              └─► Update image tag in Helm values.yaml → Push to Git        │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                          GitOps (Argo CD)                                   │
│                                                                             │
│   Git repo (Helm chart + values) ──► Argo CD watches ──► auto-sync to EKS  │
│   Any manual cluster change is reverted (drift detection + reconciliation)  │
└─────────────────────────────────┬───────────────────────────────────────────┘
                                  │
                                  ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Amazon EKS Cluster                                   │
│                                                                             │
│   ┌───────────────────────────────────────────────────────────────────┐    │
│   │  Public Subnets (ALB)          Private Subnets (Nodes)            │    │
│   │                                                                    │    │
│   │  ┌──────────┐                 ┌────────────────────────────────┐  │    │
│   │  │   ALB    │─────────────────│      order-api (Flask)         │  │    │
│   │  │ Ingress  │                 │      Deployment + HPA           │  │    │
│   │  └──────────┘                 └────────────┬───────────────────┘  │    │
│   │                                            │ HTTP invoke          │    │
│   │                                            ▼                      │    │
│   │                               ┌────────────────────────┐          │    │
│   │                               │   AWS Lambda           │          │    │
│   │                               │   order-processor      │          │    │
│   │                               └────────────────────────┘          │    │
│   │                                                                    │    │
│   │  ┌──────────────────────────────────────────────────────────┐     │    │
│   │  │  Dynatrace Operator + DynaKube (full-stack observability) │     │    │
│   │  └──────────────────────────────────────────────────────────┘     │    │
│   └───────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────┘

Infrastructure provisioned by Terraform:
  VPC → Subnets → NAT Gateway → EKS → Managed Node Group → ECR → Lambda → IAM
```

---

## Naming convention

All resources follow a consistent pattern across Terraform, Kubernetes, and IAM:

```
<project>-<environment>-<component>
```

Examples:

| Resource | Name |
|---|---|
| EKS cluster | `ekslambda-dev-eks` |
| VPC | `ekslambda-dev-vpc` |
| Flask API | `ekslambda-dev-order-api` |
| Lambda function | `ekslambda-dev-order-processor` |
| GitHub Actions IAM role | `ekslambda-dev-gha-deploy-role` |

See [`docs/NAMING_CONVENTION.md`](docs/NAMING_CONVENTION.md) for the full convention including IAM roles, S3 buckets, and Kubernetes namespaces.

---

## Repository structure

```
.
├── app/
│   └── order-api/              # Python Flask API (Dockerfile, app.py, requirements.txt)
│
├── lambda/
│   └── order-processor/        # AWS Lambda function source (Python)
│
├── helm/
│   └── order-api/              # Helm chart for EKS deployment
│       ├── Chart.yaml
│       ├── values.yaml         # image.tag updated by GitHub Actions on each build
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml    # ALB Ingress with AWS annotations
│           └── hpa.yaml
│
├── gitops/
│   └── argocd/
│       └── application.yaml    # Argo CD Application pointing to helm/order-api
│
├── infra/
│   └── terraform/
│       ├── modules/            # Reusable modules: vpc, eks, ecr, lambda, iam
│       └── envs/
│           └── dev/
│               ├── main.tf
│               ├── terraform.tfvars        # ← edit this first
│               ├── backend.hcl.example
│               └── outputs.tf
│
├── platform/
│   ├── dynatrace/
│   │   └── dynakube.yaml       # DynaKube CR for Dynatrace Operator
│   └── monitoring/
│       └── kube-prometheus-stack-values.yaml   # Optional OSS monitoring
│
├── scripts/
│   └── powershell/             # Windows PowerShell helper scripts
│
├── .github/
│   └── workflows/
│       ├── build-and-push.yml  # Build Docker image → ECR, update Helm tag
│       └── validate.yml        # Optional: Helm lint + Terraform validate on PR
│
└── docs/
    ├── STEP_BY_STEP.md         # Full deployment walkthrough
    ├── NAMING_CONVENTION.md    # Resource naming rules
    ├── ARCHITECTURE.md         # Detailed architecture decisions
    ├── GITOPS_FLOW.md          # How Argo CD promotes changes
    ├── DYNATRACE_SETUP.md      # Dynatrace Operator installation guide
    └── TROUBLESHOOTING.md      # Common errors and fixes
```

---

## Prerequisites

```bash
# Verify all required tools are installed
terraform --version     # >= 1.5
aws --version           # >= 2.x
kubectl version         # >= 1.28
helm version            # >= 3.12
docker --version        # >= 24.x
python3 --version       # >= 3.11 (for local app testing)
argocd version          # Argo CD CLI (optional, for CLI-based sync)
```

AWS permissions required: ability to create VPC, EKS, Lambda, ECR, IAM roles, and S3 (for Terraform state).

---

## Deployment order

Follow these steps exactly on first deployment. Each step depends on the previous.

### 1. Configure Terraform variables

```bash
cd infra/terraform/envs/dev
cp backend.hcl.example backend.hcl

# Edit terraform.tfvars — set your project name, region, and account ID
vim terraform.tfvars
```

Key variables to set:

```hcl
project_name   = "ekslambda"
environment    = "dev"
aws_region     = "ap-south-1"
aws_account_id = "123456789012"
```

### 2. Bootstrap Terraform backend

```bash
# Create S3 bucket and DynamoDB table for state
terraform init
terraform apply -target=module.backend
# Update backend.hcl with the bucket name from output, then re-init
terraform init -backend-config=backend.hcl -reconfigure
```

### 3. Apply infrastructure

```bash
terraform plan -out=tfplan
terraform apply tfplan
```

This provisions: VPC, subnets, NAT Gateway, EKS cluster, managed node group, ECR repository, Lambda function, and all IAM roles (including the GitHub Actions OIDC role).

### 4. Update kubeconfig

```bash
aws eks update-kubeconfig \
  --region ap-south-1 \
  --name ekslambda-dev-eks

kubectl get nodes
```

### 5. Install AWS Load Balancer Controller

```bash
# IRSA is already created by Terraform
helm repo add eks https://aws.github.io/eks-charts
helm repo update

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  --namespace kube-system \
  --set clusterName=ekslambda-dev-eks \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller
```

### 6. Install Argo CD

```bash
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for Argo CD to be ready
kubectl wait --for=condition=available deployment/argocd-server \
  --namespace argocd --timeout=120s

# Get initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Access Argo CD UI:
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# Open https://localhost:8080 (admin / password from above)
```

### 7. Configure GitHub repository variables

Go to your repo → **Settings → Secrets and variables → Actions → Variables** and add:

| Variable | Value |
|---|---|
| `AWS_REGION` | `ap-south-1` |
| `AWS_ACCOUNT_ID` | `123456789012` |
| `ECR_REPOSITORY` | `ekslambda-dev-order-api` |
| `EKS_CLUSTER_NAME` | `ekslambda-dev-eks` |
| `AWS_ROLE_TO_ASSUME` | `arn:aws:iam::123456789012:role/ekslambda-dev-gha-deploy-role` |
| `HELM_VALUES_PATH` | `helm/order-api/values.yaml` |

No static AWS credentials — GitHub Actions authenticates via OIDC.

### 8. Push code to trigger the pipeline

```bash
git add .
git commit -m "feat: initial deployment"
git push origin main
```

GitHub Actions will:
1. Build the Flask Docker image
2. Push it to ECR tagged with the Git SHA
3. Update `image.tag` in `helm/order-api/values.yaml`
4. Commit the tag update back to the repo

### 9. Apply the Argo CD Application

```bash
kubectl apply -f gitops/argocd/application.yaml
```

Argo CD detects the Helm values change from the pipeline, syncs the chart, and deploys the updated pod to EKS. From this point, every push to `main` flows automatically through the pipeline → Git → Argo CD → EKS.

### 10. Install Dynatrace Operator

```bash
# Create namespace
kubectl create namespace dynatrace

# Install Dynatrace Operator via Helm
helm repo add dynatrace https://raw.githubusercontent.com/Dynatrace/dynatrace-operator/main/config/helm/repos/stable
helm repo update

helm upgrade --install dynatrace-operator dynatrace/dynatrace-operator \
  --namespace dynatrace \
  --atomic

# Create the API token secret (get token from Dynatrace → Access tokens)
kubectl create secret generic dynakube \
  --namespace dynatrace \
  --from-literal=apiToken=<YOUR_API_TOKEN> \
  --from-literal=dataIngestToken=<YOUR_DATA_INGEST_TOKEN>

# Apply the DynaKube CR (update your Dynatrace environment URL first)
vim platform/dynatrace/dynakube.yaml   # set apiUrl
kubectl apply -f platform/dynatrace/dynakube.yaml
```

See [`docs/DYNATRACE_SETUP.md`](docs/DYNATRACE_SETUP.md) for full Dynatrace configuration including alerting, SLOs, and custom dashboards.

### 11. Validate everything

```bash
# Pods running
kubectl get pods -n order-api

# ALB provisioned
kubectl get ingress -n order-api

# Argo CD sync status
argocd app get ekslambda-dev-order-api

# Lambda reachable from the API (check app logs)
kubectl logs -n order-api deployment/order-api --tail=20

# Dynatrace agent injected
kubectl get pods -n dynatrace
kubectl describe pod -n order-api -l app=order-api | grep dynatrace
```

---

## CI/CD pipeline — how it works

```
.github/workflows/build-and-push.yml

Trigger: push to main branch

Steps:
  1. Checkout code
  2. Configure AWS credentials via OIDC (no static keys)
  3. Login to Amazon ECR
  4. Docker build: app/order-api/
  5. Trivy image scan (fail on CRITICAL CVEs)
  6. Push image to ECR: <account>.dkr.ecr.<region>.amazonaws.com/ekslambda-dev-order-api:<git-sha>
  7. Update helm/order-api/values.yaml: image.tag = <git-sha>
  8. Git commit + push the values.yaml change back to main
  9. Argo CD detects the change and syncs automatically
```

The pipeline never runs `kubectl` or `helm upgrade` directly — it only updates Git. Argo CD is the sole actor that touches the cluster. This is the GitOps contract.

---

## GitOps flow — how Argo CD promotes changes

```
Developer pushes code
       │
       ▼
GitHub Actions builds image, pushes to ECR
       │
       ▼
GitHub Actions updates helm/order-api/values.yaml (image.tag = new SHA)
       │
       ▼
Argo CD detects Git change (polls every 3 minutes or via webhook)
       │
       ▼
Argo CD runs: helm template | kubectl apply
       │
       ▼
Kubernetes rolling update: old pod stays running until new pod is Ready
       │
       ▼
Old pod terminated — zero downtime deployment
```

If someone manually edits a Kubernetes resource, Argo CD detects the drift and reverts it on the next sync. Git is always the source of truth.

See [`docs/GITOPS_FLOW.md`](docs/GITOPS_FLOW.md) for sync policies, manual override procedures, and rollback steps.

---

## Application — Flask order API

```
app/order-api/
├── app.py              # Flask routes: POST /orders, GET /health
├── requirements.txt    # Flask, boto3, requests
└── Dockerfile          # Multi-stage: build → runtime (non-root, minimal image)
```

The order API:
1. Receives a `POST /orders` request
2. Validates the payload
3. Invokes the Lambda `ekslambda-dev-order-processor` function via boto3
4. Returns the Lambda response to the caller

Local run:
```bash
cd app/order-api
pip install -r requirements.txt
python app.py

# Test
curl -X POST http://localhost:5000/orders \
  -H "Content-Type: application/json" \
  -d '{"product_id": "laptop", "quantity": 2, "amount": 1499.99}'
```

---

## Lambda — order processor

```
lambda/order-processor/
├── handler.py          # Lambda entry point: validates, processes, returns result
└── requirements.txt    # Dependencies (packaged into the Lambda zip by Terraform)
```

The Lambda function receives the order payload from the Flask API, runs processing logic (validation, inventory check simulation, confirmation), and returns a structured response.

Terraform packages the Lambda automatically from the `lambda/order-processor/` directory — no manual zip step required.

Test Lambda directly:
```bash
aws lambda invoke \
  --function-name ekslambda-dev-order-processor \
  --payload '{"product_id":"laptop","quantity":2,"amount":1499.99}' \
  --cli-binary-format raw-in-base64-out \
  response.json

cat response.json
```

---

## Observability — Dynatrace

Dynatrace provides full-stack observability across the entire platform via automatic injection:

| What Dynatrace observes | How |
|---|---|
| Pod CPU, memory, restarts | Dynatrace Operator injects OneAgent into each pod |
| HTTP request traces (Flask API) | Automatic instrumentation — no code changes |
| Lambda invocation traces | AWS Lambda integration via API token |
| EKS node metrics | `classicFullStack` mode in DynaKube |
| Service-to-service call map | Distributed traces across Flask → Lambda |
| Kubernetes events | DynaKube CR monitors cluster state |

After Dynatrace is installed, navigate to:
- **Services** — see the Flask order-api service with request rates and error rates
- **Distributed Traces** — see the full call chain from HTTP request → Flask → Lambda invocation
- **Kubernetes** — cluster health, node resource usage, pod lifecycle events

See [`docs/DYNATRACE_SETUP.md`](docs/DYNATRACE_SETUP.md) for dashboard setup, alerting profiles, and SLO configuration.

---

## Optional: Prometheus + Grafana monitoring

If you prefer an open-source observability stack or want to run both alongside Dynatrace:

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

kubectl create namespace monitoring

helm upgrade --install kube-prometheus-stack \
  prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  -f platform/monitoring/kube-prometheus-stack-values.yaml

# Access Grafana
kubectl port-forward -n monitoring svc/kube-prometheus-stack-grafana 3000:80
# Open http://localhost:3000 (admin / prom-operator)
```

The Flask app exposes `/metrics` in Prometheus format. A `ServiceMonitor` in the Helm chart enables automatic scraping.

---

## Key design decisions

**Why Argo CD instead of `helm upgrade` in the pipeline?**
Running `helm upgrade` in CI couples deployment to the pipeline — if the pipeline is broken, nothing can deploy. Argo CD separates *building* from *deploying*. The cluster can be updated directly from Git without touching CI, and CI failures don't block emergency patches.

**Why GitHub OIDC instead of IAM access keys?**
Long-lived AWS keys stored in GitHub Secrets are a credential leak risk. OIDC lets GitHub Actions assume an IAM role for the duration of the workflow only — the credential expires when the job ends, and there is nothing to rotate.

**Why does the pipeline update the Helm values file and commit back to Git?**
This is the GitOps pattern — Git is the single source of truth for what is deployed. Argo CD reads from Git. If the pipeline ran `kubectl apply` directly, the cluster state would diverge from Git on the next Argo CD sync. The values commit ensures Git always reflects exactly what is running.

**Why private EKS nodes with VPC endpoints?**
Worker nodes have no public IPs. ECR image pulls, CloudWatch logging, and S3 access route through VPC endpoints — keeping all control-plane traffic off the public internet and eliminating NAT costs for these traffic patterns.

**Why Dynatrace OneAgent injection instead of Prometheus sidecars?**
OneAgent injects automatically into pods without any application code changes, Dockerfile changes, or Helm template changes. It captures distributed traces, JVM/runtime metrics, and infrastructure metrics from a single operator. For a learning project this demonstrates how enterprise observability tooling works.

---

## Troubleshooting

**Pods stuck in `ImagePullBackOff`**
```bash
kubectl describe pod <pod-name> -n order-api
# Check: ECR URI correct in values.yaml? Node can reach ECR? IRSA attached?
aws ecr describe-images --repository-name ekslambda-dev-order-api
```

**ALB not created after Argo CD sync**
```bash
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress order-api -n order-api
# Verify public subnets have tag: kubernetes.io/role/elb = 1
```

**Argo CD shows OutOfSync after manual kubectl edit**
```bash
argocd app sync ekslambda-dev-order-api
# Argo CD will revert the manual change and restore Git state
```

**GitHub Actions cannot assume IAM role**
```bash
# Check OIDC subject format in the IAM trust policy
# Must match: repo:<org>/<repo>:ref:refs/heads/main
aws iam get-role --role-name ekslambda-dev-gha-deploy-role \
  --query 'Role.AssumeRolePolicyDocument'
```

**Lambda invocation returns 403 from Flask API**
```bash
# Check the Lambda execution role has correct permissions
# Check the EKS pod's service account has the IRSA IAM role attached
kubectl describe sa order-api -n order-api
```

**Dynatrace OneAgent not injecting into pods**
```bash
kubectl get dynakube -n dynatrace
kubectl describe dynakube ekslambda-dev -n dynatrace
# Common cause: API token missing dataIngestToken, or wrong apiUrl format
```

See [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) for the complete error reference.

---

## Production hardening checklist

This project is intentionally built as a learning and portfolio reference. For a production deployment, add the following:

**Repository separation**
- [ ] Split infrastructure Terraform into a dedicated `infra` repo
- [ ] Keep GitOps Helm charts in a dedicated `gitops` repo separate from app code
- [ ] Add branch protection rules on `main` (require PR + reviewer approval)

**Security**
- [ ] Add Secrets scanning (GitHub Advanced Security or `trufflesecurity/trufflehog` action)
- [ ] Replace Dynatrace free trial with licensed environment
- [ ] Add Policy-as-Code (OPA Gatekeeper or Kyverno) for Kubernetes admission control
- [ ] Enable EKS envelope encryption for etcd secrets
- [ ] Add network policies to restrict pod-to-pod traffic
- [ ] Configure Argo CD with SSO (Okta / Azure AD) — remove default admin account

**IAM**
- [ ] Scope the GitHub Actions IAM role to ECR push + EKS access only (no `*` actions)
- [ ] Add IAM permission boundaries on all roles
- [ ] Enable AWS CloudTrail for all API calls

**Observability**
- [ ] Configure Dynatrace alerting profiles for error rate, latency, and pod restarts
- [ ] Create Dynatrace SLOs for the order-api service
- [ ] Set up Dynatrace PagerDuty / Slack integration for alerts

**Reliability**
- [ ] Set `minReplicas: 2` in HPA for zero-downtime during node recycling
- [ ] Add `PodDisruptionBudget` for the order-api deployment
- [ ] Configure Argo CD notifications for sync failures
- [ ] Test rollback procedure: `argocd app rollback` to a previous Helm release

---

## Rollback procedures

**Application rollback via Argo CD**
```bash
# View release history
argocd app history ekslambda-dev-order-api

# Roll back to a previous revision
argocd app rollback ekslambda-dev-order-api <revision-number>
```

**Infrastructure rollback via Terraform**
```bash
# Review what changed
terraform plan

# Target a specific resource to restore
terraform apply -target=module.eks
```

**Emergency: direct Helm rollback**
```bash
helm history order-api -n order-api
helm rollback order-api <revision> -n order-api
# NOTE: this will cause Argo CD drift — re-sync after stabilising
```

---

## Interview explanation

> I built a reference platform that covers the full modern DevOps stack on AWS. The infrastructure is provisioned with Terraform — VPC, EKS, Lambda, ECR, and all IAM roles including the GitHub Actions OIDC role. A Python Flask API runs on EKS and invokes an AWS Lambda order processor for serverless processing logic. The CI/CD pipeline uses GitHub Actions with OIDC, so there are no long-lived AWS keys anywhere — the workflow assumes an IAM role for the duration of the job only. The pipeline builds the Docker image, scans it with Trivy, pushes it to ECR, and commits the new image tag back to Git. That's the GitOps pattern: Argo CD watches the Git repo and syncs the Helm chart to EKS whenever the tag changes. The cluster state always reflects Git — if someone manually edits a resource, Argo CD reverts it. Observability is handled by the Dynatrace Operator, which injects OneAgent automatically into pods without any code changes, capturing distributed traces from HTTP request through Flask through Lambda, plus all infrastructure and Kubernetes metrics.

---

## Documentation index

| Document | Contents |
|---|---|
| [`docs/STEP_BY_STEP.md`](docs/STEP_BY_STEP.md) | Complete deployment walkthrough with screenshots |
| [`docs/NAMING_CONVENTION.md`](docs/NAMING_CONVENTION.md) | Resource naming rules and rationale |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | Detailed architecture decisions and trade-offs |
| [`docs/GITOPS_FLOW.md`](docs/GITOPS_FLOW.md) | Argo CD sync policy, rollback, and override procedures |
| [`docs/DYNATRACE_SETUP.md`](docs/DYNATRACE_SETUP.md) | Dynatrace Operator install, token setup, dashboards, SLOs |
| [`docs/TROUBLESHOOTING.md`](docs/TROUBLESHOOTING.md) | Common errors and fixes |

---

## Topics

`aws` `eks` `lambda` `terraform` `github-actions` `helm` `argocd` `gitops` `dynatrace` `kubernetes` `iac` `ci-cd` `devops` `python` `flask` `observability` `platform-engineering` `oidc` `ecr`
