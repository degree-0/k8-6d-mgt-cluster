terraform {
  required_providers {
    linode = {
      source  = "linode/linode"
      version = "2.7.1"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17"
    }

  }
} 

provider "linode" {
  token = var.linode_token
}
provider "helm" {
  kubernetes {
    config_path = "kube-config"
  }
}


resource "linode_lke_cluster" "lke_cluster" {
  label       = var.label
  k8s_version = "1.31"
  region      = var.region
  tags        = var.tags

  dynamic "pool" {
    for_each = var.pools
    content {
      type  = pool.value.type
      count = pool.value.count
    }
  }
} 

resource "helm_release" "ingress-nginx" {
  depends_on   = [local_file.kubeconfig]
  name       = "ingress"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
}