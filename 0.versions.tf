terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.71"
    }
    teleport = {
      source  = "terraform.releases.teleport.dev/gravitational/teleport"
      version = "~> 16.4.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~>2.16"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.33"
    }
  }
}