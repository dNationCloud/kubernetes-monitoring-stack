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

# Installation
Prerequisites
* [Helm3](https://helm.sh/)
* For production environment we recommend (based on our experience) a kubernetes cluster with at least 2 worker nodes and 4 GiB RAM per node or more.


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

# Kubernetes support (tested)

||dNation monitoring v1.3|dNation monitoring v1.4|
|-|-|-|
|Kubernetes v1.17|✓||
|Kubernetes v1.18|✓||
|Kubernetes v1.19|✓||
|Kubernetes v1.20|✓||
|Kubernetes v1.21||✓|
|Kubernetes v1.22||✓|

# Contribution guidelines
If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs.

# Commercial support
This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

Commercial support is available, including 24/7, please [contact us](mailto:cloud@dNation.cloud?subject=Request%20for%20commercial%20support%20of%20dNation%20Kubernetes%20Monitoring).
