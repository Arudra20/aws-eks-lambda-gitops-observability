param(
    [string]$AwsRegion = "ap-south-1",
    [string]$ClusterName = "ekslambda-dev-eks"
)

$ErrorActionPreference = "Stop"

aws eks update-kubeconfig --region $AwsRegion --name $ClusterName

kubectl get nodes -o wide
kubectl get pods -A
