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
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.25.9
```

Install Kubernetes Monitoring Stack
```bash
helm install monitoring chart --dependency-update -f helpers/values-kind.yaml
```

Follow installation notes and use Port Forwarding if you want to access the Grafana server from outside your KinD cluster
```bash
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 3000
```

## dNation Brand

dNation uses re-branded version of Grafana. This is done by basic script which needs to be mounted as k8s [secret](../chart/templates/dnation/brand.yaml).
Raw form of scrips is available [here](dnation_brand.sh). If you want to re-generate k8s secret use following:
```bash
kubectl create secret generic dnation-brand --from-file=helpers/dnation_brand.sh --dry-run -o yaml
```
