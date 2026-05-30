param(
    [string]$AwsRegion = "ap-south-1",
    [string]$ClusterName = "ekslambda-dev-eks",
    [string]$VpcId,
    [string]$ServiceAccountRoleArn
)

$ErrorActionPreference = "Stop"

if (-not $VpcId) { throw "Pass -VpcId from Terraform/network output." }
if (-not $ServiceAccountRoleArn) { throw "Pass -ServiceAccountRoleArn for AWS Load Balancer Controller IRSA role." }

helm repo add eks https://aws.github.io/eks-charts
helm repo update eks

kubectl create serviceaccount aws-load-balancer-controller -n kube-system --dry-run=client -o yaml | kubectl apply -f -

kubectl annotate serviceaccount aws-load-balancer-controller `
  -n kube-system `
  eks.amazonaws.com/role-arn=$ServiceAccountRoleArn `
  --overwrite

helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller `
  -n kube-system `
  --set clusterName=$ClusterName `
  --set serviceAccount.create=false `
  --set serviceAccount.name=aws-load-balancer-controller `
  --set region=$AwsRegion `
  --set vpcId=$VpcId

kubectl get deployment -n kube-system aws-load-balancer-controller
