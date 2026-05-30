# Step-by-step project execution

This guide assumes Windows PowerShell because that is usually more convenient for this setup.

## 0. Prerequisites

Install:

- AWS CLI v2
- Terraform
- kubectl
- Helm
- Docker Desktop
- Git
- GitHub account
- Dynatrace free trial account

Check tools:

```powershell
.\scripts\powershell\00-prereq-check.ps1
```

Configure AWS:

```powershell
aws configure
aws sts get-caller-identity
```

## 1. Create GitHub repository

Create a repository:

```text
eks-lambda-gitops-observability
```

Push this project:

```powershell
git init
git add .
git commit -m "initial eks lambda gitops observability project"
git branch -M main
git remote add origin https://github.com/YOUR_GITHUB_ORG/eks-lambda-gitops-observability.git
git push -u origin main
```

## 2. Bootstrap Terraform backend

Pick a globally unique bucket name:

```powershell
.\scripts\powershell\01-bootstrap-backend.ps1 `
  -BucketName ekslambda-dev-tfstate-<account-id>
```

Then:

```powershell
cd infra/terraform/envs/dev
Copy-Item backend.hcl.example backend.hcl
Copy-Item terraform.tfvars.example terraform.tfvars
```

Update:

```text
backend.hcl
terraform.tfvars
```

## 3. Provision AWS infra

```powershell
cd ../../../../
.\scripts\powershell\02-terraform-apply.ps1
```

Capture outputs:

```powershell
cd infra/terraform/envs/dev
terraform output
```

Important outputs:

- `cluster_name`
- `ecr_repository_url`
- `github_actions_role_arn`
- `lambda_function_name`
- `lambda_invoke_irsa_role_arn`

## 4. Update kubeconfig

```powershell
cd ../../../../
.\scripts\powershell\03-update-kubeconfig.ps1 `
  -AwsRegion ap-south-1 `
  -ClusterName ekslambda-dev-eks
```

Validate:

```powershell
kubectl get nodes -o wide
kubectl get pods -A
```

## 5. Update Helm values

Open:

```text
helm/order-api/values-dev.yaml
```

Replace:

```text
REPLACE_WITH_ECR_REPOSITORY_URI
REPLACE_WITH_TERRAFORM_IRSA_ROLE_ARN
```

Use Terraform outputs:

```powershell
terraform output -raw ecr_repository_url
terraform output -raw lambda_invoke_irsa_role_arn
```

Commit these changes:

```powershell
git add helm/order-api/values-dev.yaml
git commit -m "configure dev helm values"
git push
```

## 6. Configure GitHub Actions variables

In GitHub repo:

```text
Settings -> Secrets and variables -> Actions -> Variables
```

Create:

| Variable | Value |
|---|---|
| `AWS_ROLE_ARN` | Terraform output `github_actions_role_arn` |
| `ECR_REPOSITORY_URI` | Terraform output `ecr_repository_url` |

## 7. Install AWS Load Balancer Controller

This repo expects AWS Load Balancer Controller for ALB Ingress.

Create an IRSA role for the controller using your preferred Terraform/eksctl method, then run:

```powershell
.\scripts\powershell\04-install-aws-load-balancer-controller.ps1 `
  -AwsRegion ap-south-1 `
  -ClusterName ekslambda-dev-eks `
  -VpcId vpc-xxxxxxxx `
  -ServiceAccountRoleArn arn:aws:iam::<account-id>:role/AmazonEKSLoadBalancerControllerRole
```

Validate:

```powershell
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl get validatingwebhookconfigurations | findstr load
```

## 8. Install Argo CD

```powershell
.\scripts\powershell\05-install-argocd.ps1
```

Port forward:

```powershell
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open:

```text
https://localhost:8080
```

Initial password:

```powershell
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
```

Decode it in PowerShell:

```powershell
$passwordBase64 = kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}"
[System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($passwordBase64))
```

## 9. Update Argo CD Application repo URL

Open:

```text
gitops/argocd/order-api-dev-application.yaml
```

Replace:

```text
https://github.com/YOUR_GITHUB_ORG/eks-lambda-gitops-observability.git
```

Commit:

```powershell
git add gitops/argocd/order-api-dev-application.yaml
git commit -m "configure argocd application repo"
git push
```

## 10. Trigger CI/CD

Any app change under `app/order-api` triggers:

```text
GitHub Actions -> Build image -> Push to ECR -> Update Helm values image tag -> Git commit -> Argo CD sync
```

To trigger:

```powershell
git commit --allow-empty -m "trigger app deployment"
git push
```

## 11. Apply Argo CD app

```powershell
.\scripts\powershell\07-deploy-argocd-app.ps1
```

Validate:

```powershell
kubectl get applications -n argocd
kubectl get pods,svc,ingress -n ekslambda-dev
```

## 12. Smoke test

```powershell
.\scripts\powershell\08-smoke-test.ps1
```

Manual test:

```powershell
$ALB = kubectl get ingress -n ekslambda-dev -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}"
curl.exe "http://$ALB/healthz"
curl.exe -X POST "http://$ALB/orders" -H "Content-Type: application/json" -d "{\"amount\":250}"
```

## 13. Install Dynatrace

Create a Dynatrace trial account and generate a Kubernetes/operator API token from Dynatrace UI.

Then:

```powershell
.\scripts\powershell\06-install-dynatrace.ps1 `
  -DynatraceApiToken "<your-token>" `
  -DynatraceApiUrl "https://YOUR_ENVIRONMENT_ID.live.dynatrace.com/api"
```

Validate:

```powershell
kubectl get pods -n dynatrace
kubectl get dynakube -n dynatrace
kubectl describe dynakube dynakube -n dynatrace
```

Restart app pods after namespace label:

```powershell
kubectl rollout restart deployment/ekslambda-dev-order-api -n ekslambda-dev
```

Then open Dynatrace and check:

- Kubernetes cluster
- Nodes
- Workloads
- Pods
- Services
- Logs/events
- Application traces if OneAgent injection is active

## 14. Cleanup

Destroy infra:

```powershell
cd infra/terraform/envs/dev
terraform destroy
```

Before destroy, delete ALB ingress resources:

```powershell
kubectl delete application ekslambda-dev-order-api -n argocd
kubectl delete ingress --all -n ekslambda-dev
```
