# creates namespace for teleport cluster per https://goteleport.com/docs/ver/15.x/deploy-a-cluster/helm-deployments/kubernetes-cluster/#install-the-teleport-cluster-helm-chart
resource "kubernetes_namespace" "teleport_cluster" {
  metadata {
    name = "teleport-cluster"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
}

# Creates KUBECONFIG to configure first teleport user
resource "local_sensitive_file" "kubeconfig" {
  content = templatefile("${path.module}/kubeconfig/kubeconfig.tpl", {
    cluster_name = module.eks.cluster_name
    clusterca    = data.aws_eks_cluster.cluster.certificate_authority[0].data
    endpoint     = data.aws_eks_cluster.cluster.endpoint
  })
  filename = "${path.module}/kubeconfig/${module.eks.cluster_name}.yaml"
}

# Read Teleport Enterprise License
data "local_sensitive_file" "license" {
  filename = var.teleport_license_filepath
}

# creates enterprise license as k8s secret
resource "kubernetes_secret" "license" {
  metadata {
    name      = "license"
    namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  }

  data = {
    "license.pem" = data.local_sensitive_file.license.content
  }

  type = "Opaque"
}



# defines helm release for teleport cluster
# teleport k8s operator is added via the operator.enabled arugmenet in the values section below
# https://goteleport.com/docs/reference/helm-reference/teleport-cluster/#aws
resource "helm_release" "teleport_cluster" {
  namespace = kubernetes_namespace.teleport_cluster.metadata[0].name
  wait      = true
  timeout   = 300

  name = "teleport-cluster"

  repository = "https://charts.releases.teleport.dev"
  chart      = "teleport-cluster"
  version    = var.teleport_version
  values = [
    <<EOF
clusterName: "${var.teleport_subdomain}.${var.aws_domain_name}"
chartMode: standalone
proxyListenerMode: multiplex
acme: true
acmeEmail: "${var.teleport_email}"
enterprise: true
persistence:
  storageClassName: gp2
operator:
  enabled: true
EOF
  ]
}

# sources the k8s service (running on an ELB) for the value of the DNS records below
data "kubernetes_service" "teleport_cluster" {
  metadata {
    name      = helm_release.teleport_cluster.name
    namespace = helm_release.teleport_cluster.namespace
  }
}

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
  records = [data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].hostname]
}

# creates wildcard record for teleport cluster on eks 
resource "aws_route53_record" "wild_cluster_endpoint" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "*.${var.teleport_subdomain}"
  type    = "CNAME"
  ttl     = "300"
  records = [data.kubernetes_service.teleport_cluster.status[0].load_balancer[0].ingress[0].hostname]
}