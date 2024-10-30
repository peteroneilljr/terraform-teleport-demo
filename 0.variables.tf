variable "prefix" {
  type        = string
  description = "description"
}
variable "create_vpc" {
  type        = bool
  default     = true
  description = "description"
}
variable "create_eks" {
  type        = bool
  default     = true
  description = "description"
}
variable "eks_public_access" {
  type        = bool
  default     = false
  description = "description"
}
# ---------------------------------------------------------------------------- #
# AWS Vars
# ---------------------------------------------------------------------------- #
variable "aws_domain_name" {
  description = "domain name to query for DNS"
  type        = string
}
variable "aws_vpc_cidr" {
  description = "value"
  type        = string
  default     = "10.0.0.0/16"
}
variable "aws_region" {
  description = "value"
  type        = string
  default     = null
}
variable "aws_profile" {
  description = "value"
  type        = string
  default     = "default"
}
variable "aws_tags" {
  description = "value"
  type        = map(any)
  default     = {}
}
# ---------------------------------------------------------------------------- #
# Teleport Vars
# ---------------------------------------------------------------------------- #
variable "teleport_license_filepath" {
  type        = string
  description = "description"
}
variable "teleport_email" {
  description = "email for teleport admin. used with ACME cert"
  type        = string
}
variable "teleport_version" {
  description = "full version of teleport (e.g. 15.1.0)"
  type        = string
  default     = "16.4.2"
}
variable "teleport_subdomain" {
  description = "subdomain to create in the provided aws domain"
  type        = string
}
variable "teleport_chart_mode" {
  description = "Chart mode for Teleport Cluster Helm chart aws or standalone"
  type        = string
}
# ---------------------------------------------------------------------------- #
# teleport resources
# ---------------------------------------------------------------------------- #
variable "teleport_resource_aws" {
  type        = bool
  default     = false
  description = "description"
}
