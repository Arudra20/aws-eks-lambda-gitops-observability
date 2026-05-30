$ErrorActionPreference = "Stop"

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -n argocd --server-side --force-conflicts `
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

Write-Host "Get initial admin password:"
Write-Host "kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d"

Write-Host "Port-forward:"
Write-Host "kubectl port-forward svc/argocd-server -n argocd 8080:443"
