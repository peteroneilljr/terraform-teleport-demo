# checks for space in availability zones
data "aws_availability_zones" "available" {
  filter {
    name   = "opt-in-status"
    values = ["opt-in-not-required"]
  }
}
locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
}
# ---------------------------------------------------------------------------- #
# VPC
# ---------------------------------------------------------------------------- #
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  create_vpc = var.create_vpc

  name = "${var.prefix}-eks-vpc"
  cidr = var.aws_vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(var.aws_vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(var.aws_vpc_cidr, 8, k + 48)]
  intra_subnets   = [for k, v in local.azs : cidrsubnet(var.aws_vpc_cidr, 8, k + 52)]

  enable_nat_gateway = true
  single_nat_gateway = true

  public_subnet_tags = {
    "kubernetes.io/role/elb" = 1
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
  }

  tags = var.aws_tags
}
