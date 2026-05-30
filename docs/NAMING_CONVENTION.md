# Naming Convention

Use:

```text
<project>-<environment>-<component>
```

Recommended values:

| Field | Example | Rule |
|---|---|---|
| project | `ekslambda` | Short, lowercase, no spaces |
| environment | `dev`, `qa`, `stage`, `prod` | Standard env names |
| component | `eks`, `vpc`, `order-api`, `order-processor` | Clear purpose |

Examples:

| Resource | Name |
|---|---|
| EKS cluster | `ekslambda-dev-eks` |
| VPC | `ekslambda-dev-vpc` |
| ECR repo | `ekslambda-dev/order-api` |
| Lambda | `ekslambda-dev-order-processor` |
| Namespace | `ekslambda-dev` |
| Helm release | `ekslambda-dev-order-api` |
| ServiceAccount | `ekslambda-dev-order-api-sa` |
| GitHub role | `ekslambda-dev-gha-deploy-role` |
| IRSA role | `ekslambda-dev-order-api-lambda-invoke-role` |

Tagging standard:

```text
Project     = ekslambda
Environment = dev
ManagedBy   = terraform
Repository  = eks-lambda-gitops-observability
```
