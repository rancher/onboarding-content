# Automated Kubernetes Cluster Deployment

This section will go over best practices for deploying a cluster using Rancher through the 'custom install' method.  it also includes opinionated terraform leveraging AWS as an example.

## Background

Rancher uses Rancher Kubernetes Engine (RKE) to deploy clusters in the same manner that the RKE CLI does that we used for the Rancher HA deployment.  Rancher can also import existing clusters installed through other methods, or manage hosted providers (EKS, AKS, GKE), but these clusters lifecycle will be managed externally from Rancher, as Rancher cannot upgrade, modify or backup clusters it did not create.

## Step 1: Define Cluster Nodes

The same OS recommendations from the Rancher HA deployment work here as well.  Also, each cluster managed by Rancher will have their own `etcd`,`controlplane` and `worker`.  However unlike the HA cluster, the roles should not be all colocated.  You should either use one role per node, or you can colocate `etcd` and `controplane`, which is what the example terraform in this example does.  We go over the reasons for this strategy in our documentation here: [Production Ready Cluster](https://rancher.com/docs/rancher/v2.x/en/cluster-provisioning/production/).  That link also has useful information around node sizing and networking requirements.

In our example, the minimum number of nodes required for a highly available cluster are 5 (3 `etcd/controlplane`, 2 `worker`), but additional workers would usually be required, as losing one worker node in this 5 node cluster would cut your total capacity in half, and there is a good chance the one remaining worker node would not be able to handle the required capacity.  If you are splitting the `etcd` and `controlplane` roles, then you would need 3 `etcd` nodes and 2 `controlplane` at a minimum.  In the example terraform you can modify the node counts in `main.tf` which defaults to 3 `etcd/controlplane` and 3 `worker` nodes.

The example defaults to `t3.large` machines, but larger machines may make sense if you are deploying larger applications, or several tools that run on all nodes.  You can also mix node sizes which will often make sense for larger clusters, as you may have different classes of worker nodes, or want your `etcd` and `controlplane` nodes to be different sizes.  Information around required infrastructure for the different roles can be found at the _Production Ready Cluster_ link above.

One last consideration is the disks for your machines.  Etcd nodes in particular are very sensitive to slow disks, so it is highly recommended to use SSDs if possible.  Also consider using larger or additional volumes if you plan to use a storage solution that leverages the disks of the nodes themselves.  Since we are deploying to AWS, we will just use the cloud provider's capability to provision EBS volumes if needed.

## Step 2: Cluster Options

1. Networking
   
    Rancher by default implements Canal as the cluster CNI.  If you require windows worker support, you will have to use flannel.  You can also have Rancher deploy Calico or Weave, or deploy your own.  Information about different CNIs can be found here (CNI)[https://rancher.com/docs/rancher/v2.x/en/faq/networking/cni-providers/]
    *terraform setting: true*

2. Project Network Isolation
   
    This feature will be turned off by default, if you are deploying in a multitenant manner and wish for each Project within Rancher to be isolated from each other on the cluster network, this should be enabled. _This is only available if the CNI is set to Canal_

3. Cloud Provider
   
    This will allow your cluster to provision external resources, usually either `services` of type loadbalancer or `persistentvolumes`.  This  will be set to Amazon in our case.  The capability of different cloud providers can be found here [Cloud Providers](https://kubernetes.io/docs/concepts/cluster-administration/cloud-providers/), but this is not an exhaustive list.

4. Private Registry
    
    This can be enabled if the images used to install this cluster need to be pulled from somewhere else, usually used for airgapped installs.  The example will leave this `Disabled`.

5. Authorized Endpoint
   
    This will allow users to access the cluster's API server directly, instead of being proxied through Rancher.  This is on by default which is how our example will have it.  If you plan to leverage this for much of your communication rather than just as a fallback in case of an outage, it is recommended that you put an LB in front of this cluster's controlplane nodes, and provide this setting with the FQDN of that LB.  If you do so, you will need to either add this FQDN in the `authentication.sans` section of your `cluster.yaml`, or provide a CA that will be used to validate the traffic from the LB.

6. Advanced Options
    
    Set snapshot restore, maybe a default PSP

7. Additional Considerations
    
    Beyond these options which are available as a form in the UI, you can also edit the `cluster.yaml` directly.  You may want to do so if you need to modify the configuration or pass extra arguments to your core kubernetes components (e.g. etcd, api-server, kubelet) as well as the addon components Rancher deploys (Ingress Controller, Metrics Server).  We will leave these options as the default in the example, but you can see examples of these configurations here [Ingress Controller Configuration](https://rancher.com/docs/rke/latest/en/config-options/add-ons/ingress-controllers/) and here [Kubernetes Default Services](https://rancher.com/docs/rke/latest/en/config-options/services/)

## Terraform

The included terraform files will stand up a cluster in AWS.  In `main.tf` you can configure the rancher version, kubernetes version and the node count.  Through the next phases we will learn how to modify this terraform as needed to add additional configuration and capabilities to our cluster.

To get this terraform working, you will need to install the rke provider which can be found at https://github.com/yamamoto-febc/terraform-provider-rke.
Once that provider is installed, you can deploy by using `terraform init` and then `terraform apply`.  Optionally `terraform plan` will show you the changes that executing the apply command will take.
   



