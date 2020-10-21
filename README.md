<a href="https://dnation.cloud/"><img width="250" alt="dNationCloud" src="https://storage.googleapis.com/ifne.eu/public/icons/dnation.png"></a>

# dNation Kubernetes Monitoring Stack

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

An umbrella helm chart for [dNation Kubernetes Monitoring](https://github.com/dNationCloud/kubernetes-monitoring) deployment. It is a collection of:

* [dnation-kubernetes-monitoring](https://github.com/dNationCloud/kubernetes-monitoring)
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [loki-stack](https://github.com/grafana/loki/tree/master/production/helm/loki-stack)

This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

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

# Contribution guidelines

If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs, please visit our discussion forum if you have any questions.
