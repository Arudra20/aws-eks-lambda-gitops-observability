param(
    [string]$Namespace = "ekslambda-dev"
)

$ErrorActionPreference = "Stop"

kubectl get pods,svc,ingress -n $Namespace

$Alb = kubectl get ingress -n $Namespace -o jsonpath="{.items[0].status.loadBalancer.ingress[0].hostname}"
Write-Host "ALB DNS: $Alb"

if ($Alb) {
    curl.exe "http://$Alb/healthz"
    curl.exe -X POST "http://$Alb/orders" -H "Content-Type: application/json" -d "{\"amount\":250}"
}
