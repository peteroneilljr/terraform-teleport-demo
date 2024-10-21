output kubernetes_service_hostname {
  value       =  data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].hostname
  description = "description"
}
