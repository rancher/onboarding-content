# Monitoring of Rancher Server & RKE Cluster

Monitoring of Rancher and Kubernetes cluster components can be achieved in two main ways:
1. Scraping metrics from `/metrics` endpoints of the Kubernetes components
2. Enabling Rancher-based monitoring (self-contained Prometheus + Grafana deployment)

## Scraping Metrics from Endpoints

Most Kubernetes components expose a `/metrics` endpoint through which operational metrics of the component can be scraped. For instance, from `kube-apiserver`, a metrics export could contain the following info:

```
etcd_request_duration_seconds_bucket{operation="listWithCount",type="/registry/management.cattle.io/clusters",le="0.05"} 772
etcd_request_duration_seconds_bucket{operation="listWithCount",type="/registry/management.cattle.io/clusters",le="0.1"} 772
etcd_request_duration_seconds_bucket{operation="listWithCount",type="/registry/management.cattle.io/clusters",le="0.25"} 773
etcd_request_duration_seconds_bucket{operation="listWithCount",type="/registry/management.cattle.io/clusters",le="0.5"} 776
```

While this is just a snippet of metrics that are exported, you can begin to get a feel for how this information is being represented and exposed. 

These metrics can be scraped using a monitoring tool of your choice. An example of such a tool would be [Prometheus](https://prometheus.io/). You could configure Prometheus to collect these metrics and store their values. From there, alerting and visualization capabilities can be built upon this data. An example of a visualization tool is [Grafana](https://grafana.com/). 

Specifics of how to implement this type of solution is outside of the scope of this document. Most organizations already have a monitoring solution in place for their traditional infrastructure. Where possible, it is recommended to leverage that existing tooling to help provide a holistic view of your systems. Certain monitoring systems may not be well-suited for this type of metrics collection, however. In those cases it is recommended to explore cloud-native solutions such as Prometheus and Grafana as mentioned above. 

## Enabling Rancher-based Monitoring

Version 2.2 of Rancher introduced a monitoring capability for Kubernetes. Specifically, Rancher enables you to deploy Prometheus & Grafana to your clusters, have those services automatically configued for a multitude of metrics and visualizations, and then integrate those visualizations into Rancher itself. 

Enabling this functionality depends on how you are configuring and managing the Rancher product.

For configuration through the user interface, you can visit Tools -> Monitoring when in cluster context of one of your clusters. Several options related to the Prometheus and Grafana deployment are made available, such as resource reservations and persistent volume configuration. 

Configuration through an infrastructure-as-code tool is a matter of changing specific configuration options. In _Automated Highly Available Deployment of Rancher Servers_, configuration of Rancher itself was accomplished through terraform. In that example, however, no monitoring capabilities were enabled. 

The following is an example of a terraform snipped using the `terraform/rancher2` provider to enable monitoring on a Rancher cluster. A `rancher2_cluster` resource is declared, and various options are set for the deployment of cluster monitoring.  This terraform is also included in the phase 2 terraform for setting up a cluster through Rancher.

```
# Create a new rancher2 RKE Cluster
resource "rancher2_cluster" "foo-custom" {
  name = "foo-custom"
  description = "Foo rancher2 custom cluster"
  rke_config {
    network {
      plugin = "canal"
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
```
