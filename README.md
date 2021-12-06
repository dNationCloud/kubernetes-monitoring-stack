<a href="https://dnation.cloud/"><img width="250" alt="dNationCloud" src="https://cdn.ifne.eu/public/icons/dnation.png"></a>

# dNation Kubernetes Monitoring Stack
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/dnationcloud)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=blue&label=Version&prefix=v&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=green&label=AppVersion&prefix=v&query=%24.appVersion&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)


An umbrella helm chart for [dNation Kubernetes Monitoring](https://github.com/dNationCloud/kubernetes-monitoring) deployment. It is a collection of:

* [dnation-kubernetes-monitoring](https://github.com/dNationCloud/kubernetes-monitoring)
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [loki-stack](https://github.com/grafana/helm-charts/tree/main/charts/loki-stack)
* [thanos](https://github.com/bitnami/charts/tree/master/bitnami/thanos) (to support multicluster monitoring)

# Installation
Prerequisites
* [Helm3](https://helm.sh/)

dNation Kubernetes Monitoring Stack umbrella chart is hosted in the [dNation helm repository](https://artifacthub.io/packages/search?repo=dnationcloud).
```bash
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update

# Install dNation Kubernetes Monitoring Stack
helm install dnation-kubernetes-monitoring-stack dnationcloud/dnation-kubernetes-monitoring-stack
```

Search for `Monitoring` dashboard in the `dNation` directory. The fun starts here :).
If you want to set the `Monitoring` dashboard as a home dashboard follow [here](https://grafana.com/docs/grafana/latest/administration/change-home-dashboard/#set-the-default-dashboard-through-preferences).
If you're experiencing issues please read the [documentation](https://dnationcloud.github.io/kubernetes-monitoring/docs/documentation) and [FAQ](https://dnationcloud.github.io/kubernetes-monitoring/helpers/FAQ/).

# [DRAFT] Multicluster monitoring support
This chart supports also setup of multicluster monitoring using Thanos. The deployment architecture follows "observer cluster/workload clusters" pattern, where there is one observer k8s cluster which provides centralized monitoring overview of multiple workload k8s clusters. Helm values files enabling the multicluster monitoring are located inside `multicluster-config/` directory. There are 4 files in total:
- `multicluster-config/observer-values.yaml` - contains config for production installation of obsrver cluster 
- `multicluster-config/workload-values.yaml` - contains config for production installation of workload cluster(s)
- `multicluster-config/observer-dev-values.yaml` - contains config for installation of obsrver cluster in development mode
- `multicluster-config/workload-dev-values.yaml` - contains config for installation of workload cluster(s) in development mode

The main difference between production and development mode is, that development mode doesn't have persistent object storage dependency enabled. This makes it easier and faster to setup development mode, using kind or minikube.

## Architecture

As mentioned earlier, we are using "observer cluster/workload clusters" pattern to implement 
multicluster monitoring. The full architecture can be seen on following diagram:

![](thanos-deployment-architecture.svg)

## Installation

### Observer cluster

```shell
helm --kube-context <observer-kubeconfig-context> \
install --atomic --timeout 5m \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/observer-values.yaml \
-f <custom-observer-values.yaml>
```

`custom-observer-values.yaml` file contains custom, user managed config values for observer cluster. Example of the file:

```yaml
thanosStorage:
  config: |-
    type: S3
    config:
      endpoint: "<url-of-the-S3-endpoint>"
      bucket: "<observer-bucket-name>"
      access_key: "<access-key>"
      secret_key: "<secret-key>"

kube-prometheus-stack:
  prometheus: 
    prometheusSpec:
      externalLabels: 
        cluster: "observer-cluster"
  grafana:
    ingress:
      hosts:
        - <grafana-endpoint>

thanos.query.stores: []
```

- `thanosStorage.config` field contains configuration of object storage used by thanos components in the observer cluster. More info can be found here: https://thanos.io/tip/thanos/storage.md/
- `kube-prometheus-stack.prometheus.prometheusSpec.externalLabels.cluster` field contains prometheus external label uniquely identifying observer cluster metrics.
- `kube-prometheus-stack.grafana.ingress.hosts` field contains list of hostnames on which the  observer grafana will be available
- `thanos.query.stores` field contains list of endpoints representing workload clusters. Everytime new workload cluster is introduced, its needs to be added to this list, so observer cluster knows about it.

### Workload cluster

```shell
helm --kube-context <workload-N-kubeconfig-context> \
install --atomic --timeout 10m \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/workload-values.yaml \
-f <custom-workload-values.yaml>
```

`custom-workload-values.yaml` file contains custom, user managed config values for workload cluster. Each workload cluster should have its own file. Example of the file:

```yaml
thanosStorage:
  config: |-
    type: S3
    config:
      endpoint: "<url-of-the-S3-endpoint>"
      bucket: "<workload-N-bucket-name>"
      access_key: "<access-key>"
      secret_key: "<secret-key>"

kube-prometheus-stack:
  prometheus: 
    prometheusSpec:
      externalLabels: 
        cluster: "workload-cluster-N"
```

- `thanosStorage.config` field contains configuration of object storage used by thanos components in the workload cluster. Each workload cluster should have its own, dedicated object storage bucket. More info can be found here: https://thanos.io/tip/thanos/storage.md/
- `kube-prometheus-stack.prometheus.prometheusSpec.externalLabels.cluster` field contains prometheus external label uniquely identifying workload cluster metrics. Each workload cluster should have unique prometheus external label.

As a last step you have to add exposed thanos-query endpoint of workload cluster into `thanos.query.stores` list in your `custom-observer-values.yaml` file, so your observer cluster knows about newly created workload cluster. 
The thanos-query component is exposed as a nodePort Service, and it should be accessible on every node of the workload cluster on port `30901` . After that, your `custom-observer-values.yaml` file should look like this:

```yaml
thanosStorage:
  config: |-
    type: S3
    config:
      endpoint: "<url-of-the-S3-endpoint>"
      bucket: "<observer-bucket-name>"
      access_key: "<access-key>"
      secret_key: "<secret-key>"

kube-prometheus-stack:
  prometheus: 
    prometheusSpec:
      externalLabels: 
        cluster: "observer-cluster"
  grafana:
    ingress:
      hosts:
        - <grafana-endpoint>

thanos.query.stores:
   - <host-or-ip-of-newly-added-workload-cluster>:30901
```

Ateter you added new workload cluster endpoint into `custom-observer-values.yaml` file, update the configuration of your observer cluster:

```shell
helm --kube-context <observer-kubeconfig-context> \
upgrade --atomic --timeout 5m --install \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/observer-values.yaml \
-f <custom-observer-values.yaml>
```
# Contribution guidelines
If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs.

# Commercial support
This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

Commercial support is available, including 24/7, please [contact us](mailto:cloud@dNation.cloud?subject=Request%20for%20commercial%20support%20of%20dNation%20Kubernetes%20Monitoring).
