# Getting Started

## Installation

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

If you want to contribute to the dNation Kubernetes Monitoring Stack project, be sure to review the
[contribution guidelines](CONTRIBUTING.md). This project adheres to dNation Kubernetes Monitoring Stack's
[code of conduct](CODE_OF_CONDUCT.md). When participating, you are required to abide by the code of conduct.

We use GitHub issues to manage requests and bugs, please visit our discussion forum if you have any questions.
