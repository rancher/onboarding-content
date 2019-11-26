# Repeatable Upgrades of RKE Cluster (Rancher Server)

Upgrades should be well understood and where possible automated as a low risk procedure. 

## Pre-requisites

This scenario assumes you have built an infrastructure using the steps outlined in _Automated Highly Available Deployment of Rancher Servers_. If you have not, it is recommended that you read that scenario first to develop the background necessary to continue. 

---
### Note - Semantic Versioning

Kubernetes (and Rancher, and many other projects) make use of [semantic versioning](https://semver.org/). Semantic versioning specifies a format of `major.minor.patch`. From the semver website:

>    Given a version number MAJOR.MINOR.PATCH, increment the:
> 
>    * MAJOR version when you make incompatible API changes,
>    * MINOR version when you add functionality in a backwards compatible manner, and
>    * PATCH version when you make backwards compatible bug fixes.

For example, as of this writing, the latest RKE version is `0.3.0` which is a major 0, minor 3, patch 0 version. References to major, minor, and patch version changes follow this scheme for the rest of the document. 

---

## Background

In _Automated Highly Available Deployment of Rancher Servers_, RKE was used to setup the Kubernetes cluster upon which Rancher was installed. For a refresher, view the contents of `rke.tf` in that scenario. 

The RKE configuration in that scenario specifies a kubernetes version as a local variable.  If this was left out each RKE version has a default for the cluster version.  As of this writing, `0.3.0` is the latest version of RKE. This version specifies `v1.15.4-rancher1-2` as the _default_ version of Kubernetes in use.

To update RKE-created clusters, the steps are fairly simple:

1. Identify next version of Kubernetes you wish to deploy, and ensure RKE compatibility
2. Update your infrastructure-as-code (in this case, updating the rke third party provider, as well as the other terraform providers used), and execute the change

### Kubernetes Versioning

Kubernetes has published versioning schemes and recommendations available [here](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/release/versioning.md#kubernetes-release-versioning) and [here](https://kubernetes.io/docs/setup/release/version-skew-policy/). 

From those documents, we can understand the following general recommendations:

1. Upgrading from one patch release to another patch release (within the same `major.minor`) is a suported, expected, low-risk operation. 
2. Kubernetes (as in the authors) recommends only upgrading two `minor` releases at most. e.g. going from `1.13` to `1.15`

*These documents also specify a supported component upgrade order. This is not being outlined here as the upgrade order is managed by RKE and should remain opaque to the administrator.*

There is a lot to comprehend within these guidelines. Certainly there is a lot to manage when upgrading Kubernetes. Fortunately, RKE makes this operation painless and easy for us to manage.

### RKE Versioning

Each version of RKE supports four Kubernetes releases:

1. `Experimental` (generally whatever the latest minor release of Kubernetes is)
2. `Default` (one release back from `Experimental`)
3. One minor release back from `Default`
4. Two minor releases back from `Default`

RKE will bump patch versions between releases. For example, RKE `0.2.8` supported the following Kubernetes versions:

```
v1.15.3-rancher1-1 (experimental)
v1.14.6-rancher1-1 (default)
v1.13.10-rancher1-2
v1.12.9-rancher1-1
```

RKE version `0.3.0` supports the following Kubernetes versions:

```
v1.16.1-rancher1-1 (experimental)
v1.15.4-rancher1-2 (default)
v1.14.7-rancher1-1
v1.13.11-rancher1-1
```

Note that in addition to incrementing (as a sliding window) the minor versions of Kubernetes, the patch versions have also incremented. This is supported under Kubernetes upgrade guidelines.

## Terraform

To change the version of kubernetes for the rke cluster, you can modify the local variable `kubernetes_version` in `main.tf`.  To get the list of valid versions for a specific rke version, you can run `rke config -l -a`.

If we were to execute `tf apply` the following actions would take place:

1. Terraform would evaluate current state and pick up the difference of Kubernetes version
2. The RKE provider would be engaged to (behing-the-scenes) execute an `rke up` that would upgrade the Kubernetes version of the underlying cluster. 

## Wrap-Up

This document covered upgrade recommendations for Kubernetes using RKE tooling, as well as how to apply those recommendations in practice. In reality, upgrades to Kubernetes should be planned carefully and executed during periods of downtime or maintenance windows. RKE makes all attempts to perform upgrades safely and successfully, but as in any other operation, failures can and do occur. 