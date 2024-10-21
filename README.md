# Create Teleport Cluster on EKS

This module creates the following
* VPC
* EKS cluster
* Teleport Cluster (Helm Deployment On EKS)
* Route53 subdomain to access the cluster via ELB

High availability mode will also create
* DynamoDB backend
* S3 storage bucket for recordings

## Modes

Standalone Mode 
Creates a Teleport cluster where all the resources are contained within EKS

High Availability Mode 
Creates a DynamoDB backend and S3 bucket to make the cluster resilient to failures. 

## Standalone Example usage

```hcl
data "aws_default_tags" "this" {}

module "teleport" {
  source = "../modules/terraform-teleport-cluster-eks"

  prefix = local.prefix

  eks_public_access = true

  aws_domain_name = "example.com"
  aws_vpc_cidr    = "10.17.0.0/16"
  aws_tags        = data.aws_default_tags.this.tags

  teleport_chart_mode       = "standalone"
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
```

## AWS High availability Example

```hcl
module "terraform-teleport-eks" {
  source = "../modules/terraform-teleport-cluster-eks"

  prefix = local.prefix

  # Pulic access is needed for initial configuration
  # You can set to false and access via Teleport after deployment
  eks_public_access = true

  aws_domain_name = "teleportdemo.com"
  aws_vpc_cidr    = "10.17.0.0/16"
  aws_tags        = data.aws_default_tags.this.tags
  aws_region      = var.aws_region

  teleport_chart_mode       = "aws"
  teleport_license_filepath = "../auth/license.pem"
  teleport_email            = "my.user@example.com"
  teleport_version          = var.teleport_version
  teleport_subdomain        = "my-teleport-cluster"
}

# ---------------------------------------------------------------------------- #
# Providers to create Kubernetes resources inside of the module
# ---------------------------------------------------------------------------- #
provider "kubernetes" {
  host                   = module.terraform-teleport-eks.host
  cluster_ca_certificate = module.terraform-teleport-eks.cluster_ca_certificate
  token                  = module.terraform-teleport-eks.token
}
provider "kubectl" {
  host                   = module.terraform-teleport-eks.host
  cluster_ca_certificate = module.terraform-teleport-eks.cluster_ca_certificate
  token                  = module.terraform-teleport-eks.token
}
provider "helm" {
  kubernetes {
    host                   = module.terraform-teleport-eks.host
    cluster_ca_certificate = module.terraform-teleport-eks.cluster_ca_certificate
    token                  = module.terraform-teleport-eks.token
  }
}
```


## Outputs Example
```sh
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

## Clean up

If you're running this module in a state file with other resources, it is best to 
use `terraform destroy` to remove the module resources before deleting the module
from your terraform code. 

```sh
terraform destroy --target='module.teleport'
```