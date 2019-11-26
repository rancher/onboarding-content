

locals {
  rancher_url       = "https://RANCHER_URL"
  rancher_token     = ""
  name              = "cluster-demo"
  rancher_version   = "v2.2.8"
  instance_type     = "t3.large"
  master_node_count = 3
  worker_node_count = 3
  kubernetes_version = "v1.14.5-rancher1-1"
  example_user_password = "example1"
  example_username = "example"
}
