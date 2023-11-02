provider "aws" {
  region = "ap-northeast-2"
}

locals {
  cluster_name = "Woozco"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "Woozco"
  cidr = "10.194.0.0/16"

  azs             = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets  = ["10.194.0.0/24", "10.194.1.0/24"]
  private_subnets = ["10.194.100.0/24", "10.194.101.0/24"]

  enable_nat_gateway     = true
  one_nat_gateway_per_az = true

  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
  }
}

module "eks" {
  source = "terraform-aws-modules/eks/aws"

  cluster_name                    = local.cluster_name
  cluster_version                 = "1.27"
  cluster_endpoint_private_access = false
  cluster_endpoint_public_access  = true

  cluster_addons = {
    coredns = {
      resolve_conflicts = "OVERWRITE"
    }
    kube-proxy = {}
    vpc-cni = {
      resolve_conflicts = "OVERWRITE"
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cloudwatch_log_group_retention_in_days = 1
  
  eks_managed_node_group_defaults = {
    ami_type                   = "AL2_x86_64"
		capacity_type              = "SPOT"
  		
    create_iam_role            = false
    # iam_role_name              = "${local.name}-eks-node-role"
    iam_role_arn               = module.iam_assumable_role_custom.iam_role_arn
    iam_role_use_name_prefix   = false
    iam_role_attach_cni_policy = true
    iam_role_additional_policies = {
      AmazonSSMManagedInstanceCore = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"  # 추가
    }      
    use_name_prefix            = false
      
    create_launch_template          = false
    use_custom_launch_template      = true
    enable_bootstrap_user_data      = true
  }
  
    
  
}