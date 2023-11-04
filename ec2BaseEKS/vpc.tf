module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "devops-vpc"
  cidr = "192.168.0.0/16"

  azs              = ["ap-northeast-2a", "ap-northeast-2c"]
  public_subnets   = ["192.168.0.0/20", "192.168.16.0/20"]
  public_subnet_names = ["devops-pub-a-sn", "devops-pub-c-sn"]
  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1  # 해당 태그 지정 시, k8s 내에서 ingress 생성 시 서브넷 자동 지정
  }

  enable_nat_gateway = false
  enable_dns_hostnames = true
  enable_dns_support = true
  map_public_ip_on_launch = true  # 퍼블릭 서브넷 내 생성되는 리소스에 자동으로 퍼블릭 IP를 할당한다.

  tags = {
    CreatedBy = "Terraform"
    kubernetes.io/cluster/devops-eks  = "shared" # nginx에서 subnet에 대해서 찾을 때 필요
  }
}

output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.vpc.vpc_id
}

output "public_subnets" {
  description = "List of IDs of public subnets"
  value       = module.vpc.public_subnets
}