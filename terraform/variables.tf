variable "linode_token" {
  description = "Linode API token"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "The region where the cluster will be created"
  type        = string
  default     = "eu-central"
}

variable "k8s_version" {
  description = "The Kubernetes version to use for this cluster"
  type        = string
  default     = "1.28"
}

variable "label" {
  description = "The unique label to assign to this cluster"
  type        = string
  default     = "6degrees-cluster"
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = list(string)
  default     = ["production", "6degrees"]
}

variable "pools" {
  description = "Node pool configurations"
  type = list(object({
    type  = string
    count = number
    tags  = list(string)
  }))
  default = [
    {
      type  = "g6-standard-2"
      count = 3
      tags  = ["production"]
    }
  ]
}

# These will be populated after cluster creation
variable "k8s_host" {
  description = "Kubernetes cluster endpoint"
  type        = string
  default     = ""
}

variable "k8s_token" {
  description = "Kubernetes cluster token"
  type        = string
  sensitive   = true
  default     = ""
}

variable "k8s_cluster_ca_certificate" {
  description = "Kubernetes cluster CA certificate"
  type        = string
  sensitive   = true
  default     = ""
} 