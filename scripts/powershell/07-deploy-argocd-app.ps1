$ErrorActionPreference = "Stop"

kubectl apply -f gitops/argocd/order-api-dev-application.yaml

kubectl get applications -n argocd
kubectl get pods -n ekslambda-dev
