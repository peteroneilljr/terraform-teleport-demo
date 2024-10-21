output "cluster_name" {
  value       = module.eks.cluster_name
  description = "description"
}
output "host" {
  value       = data.aws_eks_cluster.cluster.endpoint
  description = "description"
}
output "cluster_ca_certificate" {
  value       = base64decode(data.aws_eks_cluster.cluster.certificate_authority[0].data)
  sensitive   = true
  description = "description"
}
output "token" {
  value       = data.aws_eks_cluster_auth.cluster.token
  sensitive   = true
  description = "description"
}
output "teleport_fqdn" {
  value       = aws_route53_record.cluster_endpoint.fqdn
  description = "description"
}
output eks_managed_node_groups {
  value       = module.eks.eks_managed_node_groups
}

# ---------------------------------------------------------------------------- #
# This output shows the command to create the first user
# ---------------------------------------------------------------------------- #
output "create_teleport_user" {
  value = <<EOT
    kubectl --kubeconfig='${abspath(local_sensitive_file.kubeconfig.filename)}'\
      --namespace='teleport-cluster' \
      exec -ti deployment/teleport-cluster-auth -- \
      tctl users add "${var.teleport_email}" --roles=access,editor
  EOT
}