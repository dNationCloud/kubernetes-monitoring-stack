# Quickstart

These page covers the process of deploying the Kubernetes monitoring solution
into the Kubernetes cluster.

The configuration options used in this tutorial result in a non-productive and simple
deployment of the Kubernetes monitoring solution. The steps do not guide users to register
certain observer targets, such as existing Kubernetes clusters or virtual machines.
Additionally, the tutorial lacks guidance for deploying optional and experimental components
like IaaS monitoring. 

At the end of this tutorial, the reader should end up with a Kubernetes cluster where the Kubernetes monitoring solution will
be installed and will monitor the Kubernetes cluster hosting it.

## Prerequisites

- Kubernetes cluster - for production environment we recommend a Kubernetes cluster with at least 3 worker nodes and 4 GiB RAM per node or more
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)
- [helm](https://helm.sh/)

## Prepare Kubernetes cluster

The Kubernetes monitoring solution is designed to operate on Kubernetes clusters. We have continuously tested it with
various Kubernetes distributions, including vanilla Kubernetes, OKD, [K3s](./k3s.md), KinD.

For local testing purposes, we recommend using [KinD](https://kind.sigs.k8s.io/docs/user/quick-start/) (Kubernetes in Docker) as follows:

```bash
kind create cluster --config helpers/kind_cluster_config.yaml --image kindest/node:v1.30.0
```

If you opt not to use KinD with the custom config we provided here, and prefer utilizing another Kubernetes cluster,
ensure that the metric endpoints for various control plane components are properly exposed.
Refer to the [docs](https://dnationcloud.github.io/kubernetes-monitoring/helpers/FAQ/#kubernetes-monitoring-shows-or-0-state-for-some-control-plane-components-are-control-plane-components-working-correctly).

## Deploy Kubernetes monitoring solution

dNation Kubernetes Monitoring Stack umbrella chart is hosted in the [dNation helm repository](https://artifacthub.io/packages/search?repo=dnationcloud).
By default, dNation Kubernetes Monitoring Stack installs Grafana with dNation dashboards, Prometheus with Thanos and Loki in simple scalable mode.

```bash
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update dnationcloud
helm upgrade --install kubernetes-monitoring dnationcloud/dnation-kubernetes-monitoring-stack
```

If you're experiencing issues please read the [documentation](../docs), go through the [FAQ](https://dnationcloud.github.io/kubernetes-monitoring/helpers/FAQ/) or create an [issue](https://github.com/dNationCloud/kubernetes-monitoring-stack/issues).

## Access the Kubernetes monitoring UI

At this point, you should have the ability to access the Kubernetes monitoring UI (Grafana) within the Kubernetes cluster.
Follow installation notes and use Port Forwarding if you want to access the Grafana server from outside your Kubernetes cluster
```bash
export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=grafana,app.kubernetes.io/instance=monitoring" -o jsonpath="{.items[0].metadata.name}")
kubectl --namespace default port-forward $POD_NAME 3000
```

Access the UI at: 

```bash
http://localhost:3000
```
- Use the default credentials:
  - username: `admin`
  - password: `pass`

Search for `Infrastructure services monitoring` dashboard in the `dNation` directory or access it directly at http://localhost:3000/d/monitoring/infrastructure-services-monitoring.
The fun starts here :).

If you want to set the `Infrastructure services monitoring` dashboard as a home dashboard follow [here](https://grafana.com/docs/grafana/latest/administration/change-home-dashboard/#set-the-default-dashboard-through-preferences).
