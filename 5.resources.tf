module "terraform-teleport-aws" {
  source                 = "git::https://github.com/peteroneilljr/Terraform-Teleport-Module-Collection.git//terraform-teleport-app-aws"
  count = var.teleport_resource_aws ? 1:0
  
  prefix                 = var.prefix
  aws_vpc_id             = module.vpc.vpc_id
  aws_security_group_id  = module.vpc.default_security_group_id
  aws_subnet_id          = module.vpc.private_subnets[0]
  teleport_proxy_address = aws_route53_record.cluster_endpoint.fqdn
  teleport_version       = var.teleport_version
}
