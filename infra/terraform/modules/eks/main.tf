module "ebs_csi_irsa_role" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name             = "${var.cluster_name}-ebs-csi"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }

  tags = var.tags
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.37"

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  cluster_endpoint_public_access = true

  enable_cluster_creator_admin_permissions = true

  authentication_mode = "API_AND_CONFIG_MAP"

  vpc_id     = var.vpc_id
  subnet_ids = var.private_subnet_ids

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role.iam_role_arn

      resolve_conflicts_on_create = "OVERWRITE"
      resolve_conflicts_on_update = "OVERWRITE"

      timeouts = {
        create = "30m"
        update = "30m"
        delete = "30m"
      }
    }

    eks_managed_node_groups = {
      general = {
        name           = "general"
        instance_types = ["t3.medium"]
        capacity_type  = "ON_DEMAND"

        iam_role_name            = "${var.cluster_name}-ng-role"
        iam_role_use_name_prefix = false

        min_size     = 2
        max_size     = 4
        desired_size = 2

        labels = {
          role = "general"
        }

        update_config = {
          max_unavailable_percentage = 50
        }
      }
    }

    access_entries = {
      github_actions = {
        principal_arn = var.github_actions_role_arn
        type          = "STANDARD"

        policy_associations = {
          cluster_admin = {
            policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
            access_scope = {
              type = "cluster"
            }
          }
        }
      }
    }

    tags = var.tags
  }
}
