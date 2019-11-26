resource "rancher2_cluster" "user-cluster" {
  name        = "${local.name}"
  description = "Terraform managed RKE cluster"
  enable_network_policy = true

  rke_config {
    kubernetes_version = local.kubernetes_version
    cloud_provider {
      name = "aws"
    }

    services {
      etcd {
        backup_config {
          enabled        = true
          interval_hours = 6
          retention      = 12

          s3_backup_config {
            access_key  = data.terraform_remote_state.server.outputs.etcBackupUserKey
            bucket_name = data.terraform_remote_state.server.outputs.etcBackupS3BucketId
            endpoint    = "s3.us-west-2.amazonaws.com"
            region      = "us-west-2"
            folder      = local.name
            secret_key  = data.terraform_remote_state.server.outputs.etcBackupUserSecret
          }
        }
      }
    }
  }
  enable_cluster_monitoring = true
  cluster_monitoring_input {
    answers = {
      "exporter-kubelets.https" = true
      "exporter-node.enabled" = true
      "exporter-node.ports.metrics.port" = 9796
      "exporter-node.resources.limits.cpu" = "200m"
      "exporter-node.resources.limits.memory" = "200Mi"
      "grafana.persistence.enabled" = false
      "grafana.persistence.size" = "10Gi"
      "grafana.persistence.storageClass" = "default"
      "operator.resources.limits.memory" = "500Mi"
      "prometheus.persistence.enabled" = "false"
      "prometheus.persistence.size" = "50Gi"
      "prometheus.persistence.storageClass" = "default"
      "prometheus.persistent.useReleaseName" = "true"
      "prometheus.resources.core.limits.cpu" = "1000m",
      "prometheus.resources.core.limits.memory" = "1500Mi"
      "prometheus.resources.core.requests.cpu" = "750m"
      "prometheus.resources.core.requests.memory" = "750Mi"
      "prometheus.retention" = "12h"
    }
  }
}

# Create a new rancher2 User
resource "rancher2_user" "example-user" {
  name = "Example User"
  username = local.example_username
  password = local.example_user_password
  enabled = true
}
# Create a new rancher2 global_role_binding for User
resource "rancher2_global_role_binding" "example" {
  name = "example"
  global_role_id = "user-base"
  user_id = rancher2_user.example-user.id
}

resource "rancher2_project" "dev-team-a" {
  name = "DevTeamA"
  cluster_id = rancher2_cluster.user-cluster.id
}

resource "rancher2_project" "dev-team-b" {
  name = "DevTeamB"
  cluster_id = rancher2_cluster.user-cluster.id
}

# Give example-user project member access to project DevTeamA
resource "rancher2_project_role_template_binding" "exampleA" {
  name = "exampleA"
  role_template_id = "project-member"
  project_id = rancher2_project.dev-team-a.id
  user_id = rancher2_user.example-user.id
}


# Give example-user read only access to project DevTeamB
resource "rancher2_project_role_template_binding" "exampleB" {
  name = "exampleB"
  role_template_id = "read-only"
  project_id = rancher2_project.dev-team-b.id
  user_id = rancher2_user.example-user.id
}

