variable teleport_license_filepath {
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
variable "aws_domain_name" {
  description = "domain name to query for DNS"
  type        = string
}
variable "teleport_subdomain" {
  description = "subdomain to create in the provided aws domain"
  type        = string
}
