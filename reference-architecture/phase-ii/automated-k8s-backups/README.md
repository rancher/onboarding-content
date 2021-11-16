Every cluster managed by Rancher should have an automated backup solution for their etcd nodes.  This can be leveraged for similar scenarios as the backup for the Rancher HA cluster itself. More information can be found here [Backing up etcd](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/backing-up-etcd/).

### _Note on Cluster Types_

> This process assumes that Rancher is installing the cluster for you. If you are leveraging a hosted soltuion (EKS, GKE, AKS etc.) or importing the cluster, Rancher will not be able to take snapshots or restore from one.

## Backup Configuration Options

By default, a cluster created by Rancher will be configured to take an etcd snapshot every 12 hours, and to retain the last 6 snapshots. These snapshots will be stored locally on each etcd node in `/opt/rke/etcd-snapshots`. We suggest backing up your snapshots off cluster as well in case you lose all your etcd nodes in a disaster scenario. If you can use S3 as a backup target, Rancher can be configured to move these automatically for you, which is how the terraform cluster script in the deployment phase is configured.

## Restore

You can restore a cluster to a previous snapshot in the UI or directly in the API.  If you lose all of your nodes, you can still restore to a snapshot after adding new nodes back to the cluster if the snapshot was stored off cluster. See [Restoring etcd](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/restoring-etcd/) for more information.

## Terraform

In the terraform script, we create an s3 bucket in AWS and provide a secret and key to the cluster configuration in `cluster-ha.tf` in the `rke_config.services.etcd.backup_config.s3_backup_config` section.
