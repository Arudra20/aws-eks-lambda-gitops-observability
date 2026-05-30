$ErrorActionPreference = "Stop"

Set-Location infra/terraform/envs/dev

if (-not (Test-Path "backend.hcl")) {
    throw "backend.hcl not found. Copy backend.hcl.example to backend.hcl and update values."
}

if (-not (Test-Path "terraform.tfvars")) {
    throw "terraform.tfvars not found. Copy terraform.tfvars.example to terraform.tfvars and update values."
}

terraform init -backend-config=backend.hcl
terraform fmt -recursive
terraform validate
terraform plan -out=tfplan
terraform apply tfplan

terraform output
