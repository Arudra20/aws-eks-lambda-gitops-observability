module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "${var.name_prefix}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = [for index, az in var.azs : cidrsubnet(var.vpc_cidr, 8, index)]
  private_subnets = [for index, az in var.azs : cidrsubnet(var.vpc_cidr, 8, index + 10)]

  enable_nat_gateway     = true
  single_nat_gateway     = false
  one_nat_gateway_per_az = true
  enable_dns_hostnames   = true
  enable_dns_support     = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = "1"
  }

  tags = var.tags
}
