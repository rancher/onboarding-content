# Automated Highly Available Deployment of Rancher Servers

The process of deploying Rancher should be well-defined, repeatable and automated as much as possible. Best practices for this include terraform plans for infrastructure, coupled with RKE for building Kubernetes and Helm for installing Rancher’s application components. 

## Background

Automation of Rancher deployment largely deals with the underlying infrastructure. That is, most of the work to be done at this step is not related to installing Rancher or even Kubernetes itself, but rather standing up the infrastructure necessary for these components.

The basic process is:

1. Setup nodes / instances / compute on the platform of choice
2. Setup load balancer of choice
3. Setup DNS record pointing to LB
4. Install Kubernetes using RKE
5. Install Rancher using Helm

### Note

The examples in this scenario use terraform to provision AWS EC2 instances, along with associated load balancers, Route 53 DNS records, security groups, etc. These scripts are designed to be an example or "jumping off" point, and should *not* be considered a general use production ready script. Rather, take the concepts in this guide and the terraform examples, and apply them to your situation and toolset. 

## Step 1: Setup nodes

Begin by selecting your desired operating system. Referring to https://rancher.com/support-maintenance-terms/, as of this writing the supported operating systems are:
* CentOS 7.5, 7.6
* RancherOS 1.5.4
* Ubuntu 16.04, 18.04
* RHEL 7.5, 7.6

It is recommended that the more "fully-fledged" operating systems be selected over something like RancherOS. This is because RancherOS, while excellent at running containers and being a small, immutable OS, lacks features that make integrations such as security and storage painful. You will be best served by choosing one of the other operating systems.

Once you have chosen an operating system, plan the number of nodes that you are going to need.

Nodes come in three flavors: etcd, controlplane, and worker. etcd nodes host instances of `etcd`, which communicate amongst themselves to form an etcd cluster. Controlplane nodes host the Kubernetes control plane components such as `kube-apiserver`, `kube-scheduler`, and others. Worker nodes are nodes that are capable of hosting user workloads.

Three nodes is the **minimum** recommended count for an HA Rancher deployment, with each node having the `etcd`, `controlplane` and `worker` roles. This provides a good balance between having highly-available components (`etcd` and `controlplane`) and resource utilization of your infrastructure. 

Three nodes is the minimum recommended number of nodes for etcd. One node does not offer high availability. Two nodes can cause etcd to suffer from [split brain](https://www.quora.com/What-is-split-brain-in-distributed-systems). Three nodes is the minimum amount that avoids these issues. In addition, when Rancher is installed, it is scaled up as a 3-instance Kubernetes `Deployment`. Three nodes therefore ensures that Rancher itself is spread across the nodes. 

You could choose to separate out the various node roles into different sets of nodes, and in fact many users choose to do this. In that situation, you could have three nodes hosting `etcd`, two or more nodes hosting `controlplane` components, and one or more `worker` nodes. This uses more of your underlying infrastructure, but can be a good choice if you are looking to deploy a large Rancher instance. (That is, a Rancher system that is supporting a large number of clusters, nodes, or both). 

Generally speaking, though, three nodes is sufficient.

The terraform in this example sets up three master nodes and three worker nodes. The master nodes host the `etcd` and `controlplane` components, while the `worker` nodes host the workload (which, in this case, is the Rancher system itself). You can see these settings in `main.tf`:

```
  master_node_count = 3
  worker_node_count = 3
```

For your implementation, consider adding similar variables. This will allow you to easily scale up or down the number of nodes in your infrastructure. 

## Step 2: Load Balancer

When Kubernetes gets setup (in a later step), the `rke` tool will deploy the Nginx Ingress Controller. This controller will listen on ports 80 & 443 of the worker nodes, answering traffic destined for specific hostnames. 

When Rancher is installed (also in a later step), the Rancher system creates an `Ingress` resource. That Ingress tells the Nginx ingress controller to listen for traffic destined for the Rancher hostname (configurable). The controller, when receiving traffic destined for the Rancher hostname, will forward that traffic to the running Rancher pods in the cluster.

This is how we get web traffic to the Rancher system. However, it also presents an issue: if each node is listening on 80/443, which node do we send traffic to? The answer is any of them. However, _that_ creates another problem: if the node we're sending traffic to becomes unavailable, what happens?

We need a load balancer in front of these nodes to solve this problem. 

A load balancer (in either Layer-7 or Layer-4 mode) will be able to balance inbound traffic to the worker nodes in this cluster. That will prevent an outage of any single node from taking down communications to our Rancher instance.

In this terraform example, we are setting up an AWS Elastic Load Balancer (ELB). This is a simple Layer-4 load balancer that will forward requests on port 80 & 443 to the worker nodes that are setup. 

For your implementation, consider if you want/need to use a Layer-4 or Layer-7 load balancer. 

A layer-4 load balancer is the simpler of the two choices - you are just forwarding TCP traffic to your nodes. Considerations may need to be taken for the _mode_ of operation of certain load balancers. Some load balancers come with the choice of things like Source NAT, virtual servers, etc. 

A layer-7 load balancer is a bit more complicated but can offer features that you may want. For instance, a layer-7 load balancer is capable of doing TLS termination at the load balancer (as opposed to Rancher doing TLS termination itself). This can be beneficial if you want to centralize your TLS termination in your infrastructure. L7 load balancing also offers the capability for your load balancer to make decisions based on HTTP attributes such as cookies, etc. that a layer-4 LB is not able to concern itself with.

## Step 3: DNS Record

Once you have setup your load balancer, you will need to create a DNS record to send traffic to this load balancer. 

Depending on your environment, this may be an A record pointing to the LB IP, or it may be a CNAME pointing to the LB hostname.

In either case, make sure this record is the hostname that you intend Rancher to respond on. You will need to specify this hostname for Rancher installation, and it is **not possible to change later.** Make sure that your decision is a final one. 

In this terraform example, we are manipulating a Route53-hosted zone, and adding an A record pointing to the ELB IP. In your implementation, you may choose to automate this using your DNS provider of choice. Or, you may need to do this out-of-band if automation of your DNS records is not possible. 

## Step 4: Install Kubernetes Using RKE

The Rancher Kubernetes Engine, or `rke` is an "extremely simple, lightning fast Kubernetes installer that works everywhere." Rancher provides RKE to make bootstrapping Kubernetes clusters as easy as possible. 

You will need to use RKE to stand up the Kubernetes cluster that you install Rancher onto. This is a requirement from a support perspective - we are only able to validate Rancher installations in a small set of environments, and RKE is our tool of choice to stand up these clusters. 

If used in a standalone fashion, the `rke` tool will require that you create a `cluster.yml` file in which you specify, among other things, the nodes upon which you intend to setup Kubernetes. Documentation of all the available options for RKE is available at https://rancher.com/docs/rke/latest/en/. 


## Step 5: Install Rancher Using Helm

Rancher itself is published as a helm chart that is easily installable on Kubernetes clusters. Through the use of helm, we can actually leverage native Kubernetes concepts to provide Rancher in a highly-available fashion. For instance, Rancher itself is deployed as 3-instance Kubernetes `Deployment`. In a 3-node (`worker`) cluster, Rancher then has an instance of itself running on each node, and so can tolerate multiple node failures while remaining available.

Rancher has many options available for install, which are documented here: https://rancher.com/docs/rancher/v2.x/en/installation/ha/helm-rancher/chart-options/. There are two very important options to consider:

1. Hostname
2. TLS configuration

### Hostname

This is the hostname at which you wish Rancher to be available. This should be the same hostname you configured in step 3. 
**This hostname cannot be changed after it is set, so please think carefully before setting this option.**

### TLS configuration

Rancher supports three TLS modes: 
1. Rancher-generated TLS certificate
2. Let's Encrypt
3. Bring-your-own certificate

The first mode is the simplest. In this case, you will need to install `cert-manager` into the cluster. Rancher utilizes cert-mananager to issue and maintain its certificates. Rancher will generate a CA certificate of its own, and sign a cert using that CA. Cert-manager is then responsible for managing that certificate. 

The second mode, Let's Encrypt, also uses cert-manager.  However, in this case, cert-manager is combined with a special `Issuer` for Let's Encrypt that performs all actions (including request and validation) necessary for getting an LE-issued cert. Please note, however, that this requires that the Rancher instance be available from the Internet.  This is the option that is configured in the provided terraform.

The third option allows you to bring your own public- or private-CA signed certificate. Rancher will use that certificate to secure websocket and HTTPS traffic. In this case, you must upload thiss certificate (and associated key) as PEM-encoded files with the name `tls.crt` and `tls.key`. 

*If you are using a private CA, you must also upload that certificate.* This is due to the fact that this private CA may not be trusted by your nodes. Rancher will take that CA certificate, and generate a checksum from it, which the various Rancher components will use to validate their connection to Rancher. 

## Terraform

In this terraform example, a 3rd party terraform RKE provider is used to control RKE's behavior in automated fashion. This provider is available at https://github.com/yamamoto-febc/terraform-provider-rke. You can see that this example includes the specification of hosts in RKE declaration based on the nodes created in earlier steps. For example:
```
  dynamic nodes {
    for_each = aws_instance.rancher-master
```

This is a terraform 0.12 block that creates node declarations dynamically from the already-created EC2 instances. There is a similar block for the worker nodes. 

RKE will communicate with these nodes via SSH, and run various Docker container to instantiate Kubernetes. Thus, it is a requirement for the nodes that you are setting up to allow inbound tcp/22 communications from the host you are running `rke` on. 

After RKE installs the kubernetes cluster, we are using the `helm` terraform provider to install Rancher and its preqrequisites. Looking at `rancher-ha.tf`, we can see that not only is Rancher installed as a helm chart, but so is cert-manager.  The script requires cert-manager as it is leveraging Let's Encrpyt as described above.

To start using the provided terraform:
1. Make sure you have terraform installed and updated
2. Install the RKE provider following the instructions in the link above
3. Copy the terraform to a directory of your choosing
4. Set your variables in `main.tf`.  This includes setting an email for Let's Encrypt, but the script can be modified if you want to use something else for your Rancher certificate.
5. `terraform init` to download the necessary providers
6. `terraform apply` will execute the scripts to provision the resources. (Optionally you can see what will be done by running `terraform plan`)

## Wrap-Up

Through this documentation and example, you should be able to arrive at a repeatable, highly-available installation of Rancher including node setup. 

Some of the steps listed here offer more options than what is included in this terraform example. In the case that you wish to use some of these options, it is recommended that you build upon our example here, combined with our documentation, to develop a workflow that fits your environment. 