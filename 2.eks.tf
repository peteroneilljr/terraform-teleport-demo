# ---------------------------------------------------------------------------- #
# EKS cluster
# ---------------------------------------------------------------------------- #

data "external" "current_ip" {
  count = var.create_eks && var.eks_public_access ? 1:0
  program = ["bash", "-c", "curl -s 'https://api.ipify.org?format=json'"]
}
locals {
  # Restric public access to the public IP from the machine running Terraform.
  current_ip = try(data.external.current_ip[0].result.ip, "")
  my_public_ip_cidr = var.eks_public_access ? ["${local.current_ip}/32"]:null
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  create = var.create_eks

  cluster_name    = "${var.prefix}-teleport"
  cluster_version = "1.31"

  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_public_access = var.eks_public_access
  cluster_endpoint_public_access_cidrs = local.my_public_ip_cidr

  # EKS Addons
  cluster_addons = {
    coredns                = { most_recent = true }
    kube-proxy             = { most_recent = true }
    vpc-cni                = { most_recent = true }
    aws-ebs-csi-driver     = {
      most_recent              = true
      service_account_role_arn = try(aws_iam_role.eks_ebs[0].arn, "")
    }
  }

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
    tags     = var.aws_tags
  }

  eks_managed_node_groups = {
    one = {
      name = "${var.prefix}-node-group-1"

      instance_types = ["t3.small"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }

    two = {
      name = "${var.prefix}-node-group-2"

      instance_types = ["t3.micro"]

      min_size     = 1
      max_size     = 2
      desired_size = 1
    }
  }
  depends_on = [
    module.vpc,
  ]
  tags = var.aws_tags
}

# ---------------------------------------------------------------------------- #
# IAM role to allow eks to create EBS volumes
# ---------------------------------------------------------------------------- #

resource "aws_iam_role" "eks_ebs" {
  count = var.create_eks ? 1:0
  name               = "${var.prefix}AmazonEKS_EBS_CSI_DriverRole"
  assume_role_policy = <<EOF
{
      "Version": "2012-10-17",
      "Statement": [
        {
          "Effect": "Allow",
          "Principal": {
            "Federated": "${module.eks.oidc_provider_arn}"
          },
          "Action": "sts:AssumeRoleWithWebIdentity",
          "Condition": {
            "StringEquals": {
              "${module.eks.oidc_provider}:aud": "sts.amazonaws.com",
              "${module.eks.oidc_provider}:sub": "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            }
          }
        }
      ]
    }
EOF
}
resource "aws_iam_role_policy_attachment" "eks_ebs" {
  count = var.create_eks ? 1:0
  role       = aws_iam_role.eks_ebs[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ---------------------------------------------------------------------------- #
# Cluster data used to create kubernetes objects
# ---------------------------------------------------------------------------- #
# sources information about an eks cluster based on its name
data "aws_eks_cluster" "cluster" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks
  ]
}
# sources auth token for eks cluster
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
  depends_on = [
    module.eks
  ]
}