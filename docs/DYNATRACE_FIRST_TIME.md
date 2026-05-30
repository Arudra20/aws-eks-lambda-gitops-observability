# Dynatrace first-time setup for EKS

## What Dynatrace gives you here

- Kubernetes cluster health
- Node health
- Workload health
- Pod restarts
- CPU/memory usage
- Kubernetes events
- Service/process topology
- Application monitoring through OneAgent injection
- Faster root-cause hints through Dynatrace Davis AI

## Steps

### 1. Create Dynatrace trial

Go to Dynatrace signup and create a trial tenant.

### 2. Get environment URL

Your API URL usually looks like:

```text
https://YOUR_ENVIRONMENT_ID.live.dynatrace.com/api
```

Use the exact URL shown in your Dynatrace tenant.

### 3. Create token

Create an operator/API token from Dynatrace UI. Required permissions depend on the current Dynatrace UI flow, but for Kubernetes Operator setup use the token suggested by Dynatrace during "Deploy Dynatrace" setup.

### 4. Install operator

```powershell
helm install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator `
  --create-namespace `
  --namespace dynatrace `
  --atomic
```

### 5. Create secret

```powershell
kubectl -n dynatrace create secret generic dynakube `
  --from-literal="apiToken=<TOKEN>"
```

### 6. Apply DynaKube

Edit:

```text
platform/dynatrace/dynakube-cloud-native-fullstack.yaml
```

Apply:

```powershell
kubectl apply -f platform/dynatrace/dynakube-cloud-native-fullstack.yaml
```

### 7. Label application namespace

```powershell
kubectl label namespace ekslambda-dev dynatrace.com/inject=true --overwrite
kubectl rollout restart deployment/ekslambda-dev-order-api -n ekslambda-dev
```

### 8. Validate

```powershell
kubectl get pods -n dynatrace
kubectl get dynakube -n dynatrace
kubectl describe dynakube dynakube -n dynatrace
kubectl get pods -n ekslambda-dev -o wide
```

### 9. What to check in Dynatrace UI

Check:

- Kubernetes > Clusters
- Workloads
- Pods
- Services
- Logs and events
- Problems
- Distributed traces, if injection is active

## Common issues

### Dynatrace pods pending

Check node capacity:

```powershell
kubectl describe pod -n dynatrace <pod-name>
kubectl top nodes
```

### DynaKube not ready

```powershell
kubectl describe dynakube dynakube -n dynatrace
kubectl logs -n dynatrace deployment/dynatrace-operator
```

### App not showing

Confirm namespace label:

```powershell
kubectl get ns ekslambda-dev --show-labels
```

Restart deployment:

```powershell
kubectl rollout restart deployment/ekslambda-dev-order-api -n ekslambda-dev
```
