# OpenShift support
## Installation

To install the chart on an OpenShift cluster, use additional helm values `helpers/openshift/values-openshift.yaml`:
```shell
helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack -f helpers/openshift/values-openshift.yaml
```

Multi cluster setup with OpenShift as a workload cluster
```shell
helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
  -f helpers/openshift/values-openshift.yaml \
  -f helpers/multicluster-config/workload-values-openshift.yaml \
  -f <custom-workload-values-sample.yaml>
```

Multi cluster setup with OpenShift as an observer cluster
```shell
helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
  -f helpers/openshift/values-openshift.yaml \
  -f helpers/multicluster-config/observer-values-openshift.yaml \
  -f <custom-observer-values-sample.yaml>
```

## Security context constraints (SCC)

The chart creates its own [SCC](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html).
If you want to use an existing SCC from your cluster, set `openshift.existingSecurityContextConstraints: <scc-name>`.

```yaml
# Example values
openshift:
  enabled: true
  # If null, create new scc
  existingSecurityContextConstraints: <scc-name>
```

## Service Accounts

It is required that all default service accounts are disabled. New service accounts must be then created and linked in values:

```yaml
# Example setting for 'promtail' service account
# Do this with all service accounts used by kubernetes-monitoring-stack
promtail:
    serviceAccount:
    create: false
    # Service account name must match service account created below
    name: 'dnation-monitoring-promtail'
# ...
openshift:
  serviceAccounts:
    # ...
    - dnation-monitoring-promtail
    # ...
```

Service accounts are already configured in `helpers/openshift/values-openshift.yaml` for single cluster setup.
For multi cluster setup, `openshift.serviceAccounts` list is overriden in `helpers/multicluster-config/workload-values-openshift.yaml`
resp. `helpers/multicluster-config/workload-values-openshift.yaml`, so only relevant service accounts are created.

## ETCD certificates

In order to monitor ETCD, copy certificates from `openshift-config` namespace.
```bash
# Namespace to install k8s monitoring
NS='dnation-monitoring'
# Get ETCD certificate from 'openshift-config' namespace
CA=$(kubectl get cm -n openshift-config etcd-metric-serving-ca -o jsonpath='{.data.ca-bundle\.crt}')
CRT=$(kubectl get secret -n openshift-config etcd-metric-client -o jsonpath='{.data.tls\.crt}' | base64 -d)
KEY=$(kubectl get secret -n openshift-config etcd-metric-client -o jsonpath='{.data.tls\.key}' | base64 -d)
# Create etcd client secret
kubectl create secret generic -n $NS  kube-etcd-client-certs --from-literal=etcd-client.key="$KEY" --from-literal=etcd-client.crt="$CRT" --from-literal=etcd-client-ca.crt="$CA"
# Copy CA bundle configmap from openshift config namespace as is
CM=$(kubectl get configmap  openshift-service-ca.crt --namespace=openshift-config -o jsonpath='{.data.service-ca\.crt}')
kubectl create cm -n $NS  serving-certs-ca-bundle --from-literal=service-ca.crt="$CM"
```
This script is also in `helpers/openshift/openshift_etcd.sh`

## Configuration

Further configuration of OpenShift monitoring is possible, see `helpers/openshift/values-openshift.yaml`.
