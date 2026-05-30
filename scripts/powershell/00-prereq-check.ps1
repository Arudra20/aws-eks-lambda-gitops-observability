$ErrorActionPreference = "Stop"

$tools = @("aws", "terraform", "kubectl", "helm", "docker", "git")
foreach ($tool in $tools) {
    Write-Host "Checking $tool..."
    & $tool --version
}

Write-Host "All basic tools are available."
