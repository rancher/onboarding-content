locals {
  name               = "rancher-onboarding"
  rancher_version    = "v2.2.8"
  kubernetes_version = "v1.14.6-rancher1-1"
  le_email           = "none@none.com"
  domain             = "example.org"
  instance_type      = "t3.large"
  master_node_count  = 3
  worker_node_count  = 3
}

variable "rancher_password" {
  type        = string
}

/*variable "github_client_id" {
  type        = string
  default     = ""
  description = "GitHub client ID for Rancher to use, if using GH auth"
}

variable "github_client_secret" {
  type        = string
  default     = ""
  description = "GitHub client secret for Rancher to use, if using GH auth"
}*/
