output "kubeconfig" {
  depends_on = [linode_lke_cluster.lke_cluster]
  description = "Base64 encoded kubeconfig"
  value       = linode_lke_cluster.lke_cluster.kubeconfig

  sensitive   = true
}

resource "local_file" "kubeconfig" {
  depends_on = [linode_lke_cluster.lke_cluster]
  filename   = "kube-config"
  content    = base64decode(linode_lke_cluster.lke_cluster.kubeconfig)
}


output "api_endpoints" {
  description = "API endpoints of the cluster"
  value       = linode_lke_cluster.lke_cluster.api_endpoints
}

output "status" {
  description = "Status of the cluster"
  value       = linode_lke_cluster.lke_cluster.status
}

output "pool_ids" {
  depends_on = [linode_lke_cluster.lke_cluster]
  description = "IDs of the node pools"
  value       = linode_lke_cluster.lke_cluster.pool[*].id
} 