# Troubleshooting

## GitHub Actions cannot assume role

Check:

```powershell
aws iam get-role --role-name ekslambda-dev-gha-deploy-role
```

Validate trust policy:

```text
repo:<org>/<repo>:ref:refs/heads/main
```

GitHub workflow must have:

```yaml
permissions:
  id-token: write
  contents: read
```

## kubectl says forbidden

Check EKS access entry:

```powershell
aws eks list-access-entries --cluster-name ekslambda-dev-eks --region ap-south-1
```

Check current identity:

```powershell
aws sts get-caller-identity
kubectl auth can-i get pods -A
```

## ALB not created

Check AWS Load Balancer Controller:

```powershell
kubectl get deployment -n kube-system aws-load-balancer-controller
kubectl logs -n kube-system deployment/aws-load-balancer-controller
kubectl describe ingress -n ekslambda-dev
```

Check subnet tags:

```text
kubernetes.io/role/elb = 1
kubernetes.io/role/internal-elb = 1
```

## Pod cannot invoke Lambda

Check ServiceAccount annotation:

```powershell
kubectl get sa ekslambda-dev-order-api-sa -n ekslambda-dev -o yaml
```

Check IRSA trust condition:

```text
system:serviceaccount:ekslambda-dev:ekslambda-dev-order-api-sa
```

Check pod env:

```powershell
kubectl exec -n ekslambda-dev deploy/ekslambda-dev-order-api -- env
```

Check Lambda logs:

```powershell
aws logs describe-log-groups --log-group-name-prefix /aws/lambda/ekslambda-dev-order-processor
```

## Dynatrace not showing app

Check namespace label:

```powershell
kubectl get ns ekslambda-dev --show-labels
```

Restart app pods:

```powershell
kubectl rollout restart deployment/ekslambda-dev-order-api -n ekslambda-dev
```

Check Dynatrace operator:

```powershell
kubectl get pods -n dynatrace
kubectl describe dynakube dynakube -n dynatrace
```
