<a href="https://dnation.cloud/"><img width="250" alt="dNationCloud" src="https://cdn.ifne.eu/public/icons/dnation.png"></a>

# dNation Kubernetes Monitoring Stack
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/dnationcloud)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=blue&label=Version&prefix=v&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=green&label=AppVersion&prefix=v&query=%24.appVersion&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)


An umbrella helm chart for [dNation Kubernetes Monitoring](https://github.com/dNationCloud/kubernetes-monitoring) deployment. It is a collection of:

* [dnation-kubernetes-monitoring](https://github.com/dNationCloud/kubernetes-monitoring)
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [thanos](https://github.com/bitnami/charts/tree/master/bitnami/thanos)
* [loki](https://github.com/grafana/loki/tree/main/production/helm/loki)
* [promtail](https://github.com/grafana/helm-charts/tree/main/charts/promtail)
* [ssl-exporter](https://github.com/dNationCloud/ssl-exporter)  # optional
* [prometheus-blackbox-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter)   # optional
* [loki-distributed](https://github.com/grafana/helm-charts/tree/main/charts/loki-distributed)  # deprecated, see [loki](docs/loki)

## Quickstart 

Refer to the [quickstart page](docs/quickstart.md).

## Documentation

Explore the documentation stored in the [docs](docs/README.md) directory.

## Contribution guidelines

If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs.

## Commercial support

This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

Commercial support is available, including 24/7, please [contact us](mailto:cloud@dNation.cloud?subject=Request%20for%20commercial%20support%20of%20dNation%20Kubernetes%20Monitoring).
