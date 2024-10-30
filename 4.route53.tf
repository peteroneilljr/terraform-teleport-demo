# used for creating subdomain on existing zone. zone is defined by the variable domain_name
data "aws_route53_zone" "main" {
  name = var.aws_domain_name
}

# creates DNS record for teleport cluster on eks
resource "aws_route53_record" "cluster_endpoint" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = var.teleport_subdomain
  type    = "CNAME"
  ttl     = "300"
  records = [local.kubernetes_service_hostname]
}

# creates wildcard record for teleport cluster on eks 
resource "aws_route53_record" "wild_cluster_endpoint" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${var.teleport_subdomain}"
  type    = "CNAME"
  ttl     = "300"
  records = [local.kubernetes_service_hostname]
}

locals {
  kubernetes_service_hostname = (
    try(module.teleport-cluster-standalone[0].kubernetes_service_hostname, # standalone
      try(module.teleport-cluster-aws[0].kubernetes_service_hostname,      # aws
        "error"
      )
    )
  )
}