param(
    [string]$DynatraceApiToken,
    [string]$DynatraceApiUrl
)

$ErrorActionPreference = "Stop"

if (-not $DynatraceApiToken) {
    throw "Pass -DynatraceApiToken from Dynatrace UI."
}
if (-not $DynatraceApiUrl) {
    throw "Pass -DynatraceApiUrl like https://YOUR_ENVIRONMENT_ID.live.dynatrace.com/api"
}

helm install dynatrace-operator oci://public.ecr.aws/dynatrace/dynatrace-operator `
  --create-namespace `
  --namespace dynatrace `
  --atomic

kubectl -n dynatrace create secret generic dynakube `
  --from-literal="apiToken=$DynatraceApiToken" `
  --dry-run=client -o yaml | kubectl apply -f -

(Get-Content platform/dynatrace/dynakube-cloud-native-fullstack.yaml) `
  -replace 'https://YOUR_ENVIRONMENT_ID.live.dynatrace.com/api', $DynatraceApiUrl |
  kubectl apply -f -

kubectl label namespace ekslambda-dev dynatrace.com/inject=true --overwrite

kubectl get pods -n dynatrace
kubectl get dynakube -n dynatrace
