# Read Teleport Enterprise License
data "local_sensitive_file" "license" {
  filename = var.teleport_license_filepath
}

# https://goteleport.com/docs/ver/15.x/deploy-a-cluster/helm-deployments/kubernetes-cluster/#install-the-teleport-cluster-helm-chart
# creates namespace for teleport cluster 
resource "kubernetes_namespace" "teleport_cluster" {
  metadata {
    name = "teleport-cluster"
    labels = {
      "pod-security.kubernetes.io/enforce" = "baseline"
    }
  }
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
chartMode: aws
enterprise: true
clusterName: "${var.teleport_subdomain}.${var.aws_domain_name}"                   # Name of your cluster. Use the FQDN you intend to configure in DNS below.
proxyListenerMode: multiplex
aws:
  region: ${var.aws_region}                # AWS region
  backendTable: ${aws_dynamodb_table.teleport_backend.name} # DynamoDB table to use for the Teleport backend
  auditLogTable: ${aws_dynamodb_table.teleport_events.name}             # DynamoDB table to use for the Teleport audit log (must be different to the backend table)
  auditLogMirrorOnStdout: false                   # Whether to mirror audit log entries to stdout in JSON format (useful for external log collectors)
  sessionRecordingBucket: ${aws_s3_bucket.teleport_sessions.bucket}  # S3 bucket to use for Teleport session recordings
  backups: true                                   # Whether or not to turn on DynamoDB backups
  dynamoAutoScaling: false                        # Whether Teleport should configure DynamoDB's autoscaling.
highAvailability:
  replicaCount: 2                                 # Number of replicas to configure
  certManager:
    issuerKind: ClusterIssuer
    enabled: true                                 # Enable cert-manager support to get TLS certificates
    issuerName: letsencrypt-production            # Name of the cert-manager Issuer to use (as configured above)
# If you are running Kubernetes 1.23 or above, disable PodSecurityPolicies
podSecurityPolicy:
  enabled: false
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