module "teleport-cluster-aws" {
  count = var.teleport_chart_mode == "aws" ? 1:0

  source                    = "./modules/teleport-cluster-aws"
  teleport_license_filepath = var.teleport_license_filepath
  teleport_version          = var.teleport_version
  teleport_subdomain        = var.teleport_subdomain
  teleport_email            = var.teleport_email
  aws_domain_name           = var.aws_domain_name
  aws_region                = var.aws_region
  aws_route53_zone_id       = data.aws_route53_zone.main.id
  eks_cluster_name          = module.eks.cluster_name
  eks_managed_node_groups   = module.eks.eks_managed_node_groups
}
module "teleport-cluster-standalone" {
  count = var.teleport_chart_mode == "standalone" ? 1:0

  source                    = "./modules/teleport-cluster-standalone"
  teleport_license_filepath = var.teleport_license_filepath
  teleport_version          = var.teleport_version
  teleport_subdomain        = var.teleport_subdomain
  teleport_email            = var.teleport_email
  aws_domain_name           = var.aws_domain_name
}
