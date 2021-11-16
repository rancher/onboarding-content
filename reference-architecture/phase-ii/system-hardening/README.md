This section will cover security considerations you may want to take in order to harden your cluster and reduce potential attack surface area and intrusion points. Most of this section is regarding configuration that will be applied after the terraform scripts. Configuration best practices for some of these tools is outside the scope of this document, but they are mentioned here to give a general overview.

## CIS Benchmarking

The Center for Internet Security (CIS) provides a benchmark assessment for securing a Kubernetes cluster. Rancher has created a self assessment guide as well as recommended tunings in order to meet these standards. If desired, many of the recommended options can be enabled within the cluster configuration in the terraform scripts.

You can find the Rancher CIS guide here: [Hardening Guide](https://rancher.com/docs/rancher/v2.x/en/security/hardening-2.3/).

## RKE Templates

Often there can be a number of users and teams in charge of deploying clusters through Rancher. In this case it is useful to be able to put controls around how clusters are deployed in addition to who can deploy them. RKE templates allow an administrator to define a cluster configuration through Rancher, and enforce whether that configuration is required to be used. The templates can only be leveraged for clusters deployed by Rancher, and will not apply for imported or hosted clusters (e.g. EKS, AKS, GKE). More information can be found [here](https://rancher.com/docs/rancher/v2.x/en/admin-settings/rke-templates/).

## Service Mesh

Rancher can also deploy Istio for managed clusters as well. Istio is a service mesh that allows operators and developers control over application traffic management and security. From a security perspective, Istio gives you the ability to require TLS communication between services in the cluster, setup rate limiting policies, and access control for traffic Ingress/Egress to services. More information can be found at the Rancher docs [here](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/tools/istio/), as well as Istio's website [here](https://istio.io/docs/tasks/).

## External Considerations

While Rancher provides you with the tools and guidance to harden a cluster, your organization may consider using an additional container security solution on top of Rancher. These external products can give you additional capabilities around vulnerability management, runtime security, secret management, regular security and compliance auditing and more. Rancher partners with Twistlock, Aquasec and Sysdig for many companies to enhance cluster security control.
