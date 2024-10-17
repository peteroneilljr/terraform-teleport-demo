# Create Teleport Cluster on EKS

This module creates the following
* VPC
* EKS cluster
* Teleport Cluster (Helm Deployment On EKS)
* Route53 subdomain to access the cluster via ELB

## Example usage

```hcl
data "aws_default_tags" "this" {}

module "teleport" {
  source = "../modules/terraform-teleport-cluster-eks"

  prefix = local.prefix

  create_vpc        = true
  create_eks        = true
  eks_public_access = true

  aws_domain_name = "example.com"
  aws_vpc_cidr    = "10.17.0.0/16"
  aws_tags        = data.aws_default_tags.this.tags

  teleport_license_filepath = "../auth/license.pem"
  teleport_email            = "my.user@example.com"
  teleport_version          = var.teleport_version
  teleport_subdomain        = "my-teleport-cluster"
}

# ---------------------------------------------------------------------------- #
# Providers to create Kubernetes resources inside of the module
# ---------------------------------------------------------------------------- #
provider "kubernetes" {
  host                   = module.teleport.host
  cluster_ca_certificate = module.teleport.cluster_ca_certificate
  token                  = module.teleport.token
}
provider "helm" {
  kubernetes {
    host                   = module.teleport.host
    cluster_ca_certificate = module.teleport.cluster_ca_certificate
    token                  = module.teleport.token
  }
}

# ---------------------------------------------------------------------------- #
# Output example to create first user
# ---------------------------------------------------------------------------- #
output create_teleport_user {
  value       = module.terraform-teleport-eks.create_teleport_user
  description = "Example kubectl command to create your first Teleport user"
}
output teleport_cluster_fqdn {
  value       = module.terraform-teleport-eks.fqdn
  description = "The URL to access your Teleport Cluster. (Ready ~10 min after module deployment)"
}
```