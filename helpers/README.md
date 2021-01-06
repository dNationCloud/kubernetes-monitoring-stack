# Helpers

A set of scripts and configuration files which helps to simplify local development.

## Local development using KinD (Kubernetes in Docker)

Prerequisites

* [Kind](https://kind.sigs.k8s.io/)
* [Docker](https://www.docker.com/)
* [Helm3](https://helm.sh/)
* [Kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/)

Create KinD cluster
```bash
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.19.1
```

Install Kubernetes Monitoring Stack
* Grafana UI is exposed on port `5000`, see http://localhost:5000
* Prometheus UI is exposed on port `5001`, see http://localhost:5001
* Prometheus Alertmanager UI is exposed on port `5002`, see http://localhost:5002
```bash
helm install monitoring chart --dependency-update -f helpers/values-kind.yaml
```

## dNation Brand

dNation uses re-branded version of Grafana. This is done by basic script which needs to be mounted as k8s [secret](../chart/templates/dnation/brand.yaml).
Raw form of scrips is available [here](dnation_brand.sh). If you want to re-generate k8s secret use following:
```bash
kubectl create secret generic dnation-brand --from-file=helpers/dnation_brand.sh --dry-run -o yaml
```

## Node Exporter

Bash script to install Node Exporter v0.18.1 on your Ubuntu host.

```bash
./helpers/node_exporter.sh
```
