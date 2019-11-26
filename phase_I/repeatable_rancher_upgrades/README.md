# Repeatable Upgrades of Rancher Server

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

In _Automated Highly Available Deployment of Rancher Servers_, Helm was used (via the terraform provider) to install Rancher as a chart on top of an RKE-provisioned Kubernetes cluster. For a refresher, view the contents of `rancher-ha.tf`. 

Note that in this configuration, there was one other application installed - the cert-manager Helm chart. Rancher makes use of cert-manager in certain TLS configurations to manage the certificates that secure Rancher communications. 

Generally speaking, Rancher TLS configurations fall into the following three categories:

| Configuration | Description | Requires cert-manager? |
| ------------- | ----------- | ---------------------- |
| Self-signed   | Rancher generates both a CA and a TLS certificate, and self-signs. | Yes |
| Bring-your-own | Bring your own certificates and Rancher will utilize them. | No |
| Let's Encrypt | Rancher will manage requesting & installing an LE certificate for you | Yes |

Of these three options, the second one (BYO certs) offers two "sub-options":

1. TLS termination in the Kubernetes cluster (at ingress)
2. TLS termination externally

In _Automated Highly Available Deployment of Rancher Servers_, Let's Encrypt certificates were requested and installed. This is evident through the usage of configuration options `tls.ingress.source` (which was set to `letsEncrypt`), and `letsEncrypt.*` options. These options are arguments passed to the Helm chart installation (and upgrade). 

Depending on your configuration, these options may be different. When upgrading Rancher, it is important to maintain the same options from install to upgrade. 

Successful upgrades of Rancher will need to execute the following steps:

1. Determine target Rancher version
2. Determine existing Rancher install options
3. Execute Rancher upgrade

## Step 1 - Determine Target Rancher Version

### Understanding Rancher Versioning

Each version of Rancher supports four Kubernetes releases:

1. `Experimental` (generally whatever the latest minor release of Kubernetes is)
2. `Default` (one release back from `Experimental`)
3. One minor release back from `Default`
4. Two minor releases back from `Default`

As of 2.3.0, Rancher  

### RKE Cluster Version

In order to remain compatible with Rancher tooling, the cluster that Rancher is installed upon should be upgraded to a Rancher-supported version. Rancher versions match RKE versions, allowing you to increment the two as you upgrade your Rancher infrastructure.

See _Repeatable Upgrades of RKE Cluster (Rancher Server)_ to learn more about upgrading the underlying RKE cluster for Rancher. The rest of this document assumes that your RKE cluster is at a Kubernetes version with which Rancher is compatible. 

### Selecting Rancher Version

Recall that Rancher's versioning follows the semantic versioning guidelines. Thus, upgrades from one patch version to another should not cause any breaking changes and should be relatively low risk. Upgrades from one minor version to another should be backwards compatible - but may (usually do) introduce new features and functionality. Major version upgrades are reserved for API changes that are not backwards compatible, or other "major" upgrade paths. 

Prior to upgrading, check Rancher's documentation on known upgrade issues. That documentation is available at https://rancher.com/docs/rancher/v2.x/en/upgrades/upgrades/#known-upgrade-issues. 

## Step 2 - Determine Existing Rancher Install Options

Rancher is installed as a Helm chart on top of an RKE-provisioned cluster. As part of being a Helm chart, Rancher comes with a littany of options that can be set during installation. These options are documented at https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/chart-options/. 

Prior to upgrading, you must document the options used to deploy Rancher. 

### Helm CLI Installs

If you installed Rancher at the CLI using `helm`, retrieving install options can be achieved in a two-step process:

1. Determine the name of your Rancher chart installation. To do so, execute `helm list` at a console that is configured for `kubectl` access to your Rancher cluster. That output should look something similar to:
    ```
    NAME        	REVISION	UPDATED                 	STATUS  	CHART              	APP VERSION	NAMESPACE    
    cert-manager	1       	Thu Oct 10 15:33:32 2019	DEPLOYED	cert-manager-v0.9.1	v0.9.1     	kube-system  
    rancher     	11      	Thu Oct 10 15:37:04 2019	DEPLOYED	rancher-2.3.0      	v2.3.0     	cattle-system
    ```
    In this instance, Rancher is deployed under the name `rancher`. 

2. Using the name of your Rancher chart installation, obtain a list of the options used to install the chart. To do so, execute `helm get values <name>` where `<name>` is the value you looked up in step 1. The output from this step will be a listing of key-value pairs that comprise the options used to install Rancher.

### Infrastructure-as-code Installs

The advantage of executing `helm` installations using an infrastructure-as-code tool is that your install options should always be available to you (provided proper maintenance and version control). 

In _Automated Highly Available Deployment of Rancher Servers_, options for Rancher installation are documented in `rancher-ha.tf`. Those options are:

* `hostname`
* `ingress.tls.source`
* `letsEncrypt.email`
* `letsEncrypt.environment`

If you have developed your own solution, these options may differ. 

Note these options, as they will be needed for the upgrade procedure. 

## Step 3 - Execute Rancher Upgrade

Before upgrading Rancher, look through the release notes for the version of Rancher to which you are upgrading. These release notes may contain deprecations of certain chart options that you may wish to adjust. 

### Helm CLI Installations

If you installed Rancher at the CLI using `helm`, upgrading is a two step process:

1. Update your helm repository. To do so, execute `helm repo update`. You may have either installed Rancher from `rancher-stable` or `rancher-latest` chart repository. *Upgrades from `rancher-alpha` to stable or latest are not supported. Alpha is not recommended for production installations.*
2. Execute the chart update command, specifying the chart options you documented in _Step 2 - Determine Existing Rancher Install Options_. This command is:
    ```
    helm upgrade rancher rancher-[stable|latest]/rancher --set <key>=<value>
    ```
    Replace `--set <key>=<value>` with your options. Repeat as many times as necessary. 

Execute the command. This will upgrade your Rancher installation. 

### Infrastructure-as-code Installs

Depening on your IaC tooling, performing this upgrade could take different forms. In _Automated Highly Available Deployment of Rancher Servers_, the version of Rancher installed is specified in `main.tf`, along with the value of options used in the installation:

```
...
  rancher_version   = "v2.2.8"
  le_email          = "none@none.com"
...
```

Performing the upgrade to a newer version of Rancher is as simple, in this case, as changing `rancher_version` from `v2.2.8` to the desired target version (keeping in mind general upgrade guidelines mentioned above). Then, we would execute `tf apply` and allow terraform to perform this upgrade for us. 