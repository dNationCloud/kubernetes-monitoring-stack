# K3s support

K3s is a certified Kubernetes distribution optimized for production environments, particularly in remote locations
or resource-constrained environments.

This page contains information on how to develop and/or test the Kubernetes solution as a monitoring solution for a k3s
cluster. It guides the user to create an HA k3s cluster via k3d (a wrapper to run k3s in Docker) and bootstrap
it with the Kubernetes monitoring solution.

Note that the following tutorial guides you to deploy an HA K3s cluster consisting of 3 control plane nodes (servers)
and one worker node (agent). The reason is that the HA K3s cluster utilizes an embedded etcd cluster as cluster storage
(refer to https://docs.k3s.io/datastore/ha-embedded).
Using a single-node K3s cluster that uses the SQLite database (default) requires additional tweaks of monitoring values,
which are not covered in this guide.

## Prerequisites

- [K3d](https://k3d.io/#installation)
- [helm](https://helm.sh/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## Prepare K3s Kubernetes cluster via K3d

```bash
k3d cluster create --config helpers/k3s/k3s-config.yaml --image rancher/k3s:v1.28.8-k3s1 observer
```

If you opt not to use K3D with the custom config we provided here, and prefer utilizing another k3s cluster,
ensure that the metric endpoints for various control plane components are properly exposed.
Refer to the [docs](https://dnationcloud.github.io/kubernetes-monitoring/helpers/FAQ/#kubernetes-monitoring-shows-or-0-state-for-some-control-plane-components-are-control-plane-components-working-correctly).

## Deploy Observer monitoring solution

K3s consolidates all Kubernetes control plane components into a single process, which means that the metrics for these
control plane components are exposed on the K3d hosts rather than through individual Kubernetes Services/PODs.
To customize monitoring values for K3s, refer to the specific custom HELM values file `helpers/k3s/values-observer-k3s.yaml`.
This file contains the necessary configurations and adjustments needed to monitor K3s.
Note that list of control plane node IPs (endpoints) should be overridden.

Get and store the K3d control plane node IPs:
```bash
NODE_IPS=$(kubectl get nodes -l node-role.kubernetes.io/control-plane=true -o jsonpath='{.items[*].status.addresses[?(@.type=="InternalIP")].address}' | tr ' ' ',' | sed 's/^/{&/;s/$/}/')
```

Install the monitoring stack and set the control plane component endpoints
```bash
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update dnationcloud
helm upgrade --install kubernetes-monitoring dnationcloud/dnation-kubernetes-monitoring-stack -f helpers/k3s/values-observer-k3s.yaml \
  --set "kube-prometheus-stack.kubeEtcd.endpoints=$NODE_IPS" \
  --set "kube-prometheus-stack.kubeProxy.endpoints=$NODE_IPS" \
  --set "kube-prometheus-stack.kubeControllerManager.endpoints=$NODE_IPS" \
  --set "kube-prometheus-stack.kubeScheduler.endpoints=$NODE_IPS"
```

# Access the Observer monitoring UIs

At this point, you should have the ability to access the Grafana, Alertmanager and Prometheus UIs
within the Observer monitoring cluster.

- Grafana UI
  ```bash
  http://localhost:30000
  ```
  - Use the following credentials:
    - username: `admin`
    - password: `pass`

  - Visit the Layer 0 dashboard, `infrastructure-services-monitoring`, and drill down to explore cluster metrics
    - http://localhost:30000/d/monitoring/infrastructure-services-monitoring

- Alertmanager UI
  ```bash
  http://localhost:30001
  ```

- Prometheus UI
  ```bash
  http://localhost:30002
  ```
