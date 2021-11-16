This document will go over considerations for setting up tooling for your Rancher managed clusters

## Logging

Logging can be configured after cluster creation.  Rancher has a built in logging tool, that will deploy Fluentd as a daemonset. Fluentd is a data collector that will scrape standard error/standard out as well as the files in `/var/log/containers` when deployed by Rancher. Fluentd can be configured to send these logs to a number of different endpoints within the UI. One of these endpoints is also Fluentd, so that users can send logs to an intermediary to perform resource intensive pre-processing of the logs if needed. Configuring a logging endpoint such as elasticsearch is outside the scope of this document.

[Rancher Logging Documentation](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/tools/logging/)

## Monitoring

Monitoring for your Rancher managed clusters can be implemented in the same manner as it is for the Rancher HA cluster itself. You can refer to the documentation in the [Rancher Server Monitoring](360042011251) Section for details. The terraform script enables cluster monitoring by default. This can be disabled and enabled manually after cluster creation, which may be desirable so a storage class can be configured first to allow grafana and prometheus to be backed up to a `PersistentVolume`.

[Rancher Monitoring Documenation](https://rancher.com/docs/rancher/v2.x/en/cluster-admin/tools/monitoring/)

_Note: You are not required to use Rancher's built in solutions for logging and monitoring.  Rancher can be used with any third party logging or monitoring solution you choose, but the built in solutions are also covered by Rancher's SLAs._
