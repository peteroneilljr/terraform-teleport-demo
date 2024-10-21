resource "kubernetes_namespace" "cert_manager" {
  metadata {
    name = "cert-manager"
  }
}

# https://registry.terraform.io/modules/terraform-iaac/cert-manager/kubernetes/latest
module "cert_manager" {
  source = "terraform-iaac/cert-manager/kubernetes"

  create_namespace = false

  cluster_issuer_email                   = var.teleport_email
  cluster_issuer_name                    = "letsencrypt-production"
  cluster_issuer_private_key_secret_name = "letsencrypt-production-key"
  cluster_issuer_server                  = "https://acme-v02.api.letsencrypt.org/directory"
  
  solvers = [
    {
      selector = {
        dnsZones = [
          (var.aws_domain_name)
        ]
      }
      dns01 = {
        route53 = {
          region       = (var.aws_region)
          hostedZoneID = (var.aws_route53_zone_id)
        }
      }
    }
  ]

  additional_set = [
    {
      name  = "global.leaderElection.namespace"
      value = "cert-manager"
    },
    {
      name  = "extraArgs"
      value = "{--issuer-ambient-credentials}"
    },
  ]
}