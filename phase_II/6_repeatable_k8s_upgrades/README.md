# Upgrading Rancher managed Kubernetes Clusters

This document will go over considerations you should keep in mind when upgrading clusters that were deployed by Rancher

## Upgrade Considerations

* Upgrades are on a per cluster basis, so not all clusters managed by one Rancher instance need to be on the same Kubernetes versions.
* In Rancher 2.3.0 and later, kubernetes versions are decoupled from the Rancher version, so upgrading Rancher is no longer required to get newer supported Kubernetes versions
* Upgrades may cause small downtime windows if certain components need to be upgraded.  For example if the kubelet or kube-proxy services need to be redeployed, routing to pods on that node may be briefly interrupted.  Likewise for addons such as the Ingress Controller.  Rancher is working to mitigate/eliminate this by allowing users to have more fine-grained control on the upgrade process in 2.4.  The ticket for this story can be found here: [Zero Downtime Plan for 2.4](https://github.com/rancher/rancher/issues/23038)
* For support reasons, you should keep your clusters upgraded to a version that fits within our support matrix for the Rancher version you are on.  This information can be found here: [Support Terms](https://rancher.com/support-maintenance-terms/).  Usually versions outside of the three most recent are are considered EOL by the community and may not receive security patches.

## Terraform

An upgrade can be accomplished in the example terraform in the _Automated Kubernetes Cluster Deployment_ section by changing the local variable `kubernetes_version`. Rerunning `terraform apply` will then trigger an upgrade to the new version.