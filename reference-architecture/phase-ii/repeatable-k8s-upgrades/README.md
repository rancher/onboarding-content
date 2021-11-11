This document will go over considerations you should keep in mind when upgrading clusters that were deployed by Rancher.

## Upgrade Considerations

* Upgrades are on a per cluster basis, so not all clusters managed by one Rancher instance need to be on the same Kubernetes versions.
* In Rancher 2.3.0 and later, Kubernetes versions are decoupled from the Rancher version, so upgrading Rancher is no longer required to get newer supported Kubernetes versions.
* Upgrades may cause small downtime windows if certain components need to be upgraded. For example if the kubelet or kube-proxy services need to be redeployed, routing to pods on that node may be briefly interrupted. Likewise for addons such as the Ingress Controller. In Rancher 2.4.0 and later, you can mitigate this during upgrade by configuring an upgrade strategy to upgrade nodes in batches, per the [documentation here](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/upgrading-kubernetes/).
* For support reasons, you should keep your clusters upgraded to a version that fits within our support matrix for the Rancher version you are on. This information can be found here: [Support Terms](https://rancher.com/support-maintenance-terms/). Usually versions outside of the three most recent are are considered EOL by the community and may not receive security patches.

## Terraform

An upgrade can be accomplished in the example terraform in the [Automated Kubernetes Cluster Deployment](360042011091) section by changing the local variable `kubernetes_version`. Rerunning `terraform apply` will then trigger an upgrade to the new version.
