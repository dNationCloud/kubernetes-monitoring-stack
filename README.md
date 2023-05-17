<a href="https://dnation.cloud/"><img width="250" alt="dNationCloud" src="https://cdn.ifne.eu/public/icons/dnation.png"></a>

# dNation Kubernetes Monitoring Stack
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)
[![Artifact HUB](https://img.shields.io/endpoint?url=https://artifacthub.io/badge/repository/dnationcloud)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=blue&label=Version&prefix=v&query=%24.version&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)
[![version](https://img.shields.io/badge/dynamic/yaml?color=green&label=AppVersion&prefix=v&query=%24.appVersion&url=https%3A%2F%2Fraw.githubusercontent.com%2FdNationCloud%2Fkubernetes-monitoring-stack%2Fmain%2Fchart%2FChart.yaml)](https://artifacthub.io/packages/search?repo=dnationcloud)


An umbrella helm chart for [dNation Kubernetes Monitoring](https://github.com/dNationCloud/kubernetes-monitoring) deployment. It is a collection of:

* [dnation-kubernetes-monitoring](https://github.com/dNationCloud/kubernetes-monitoring)
* [kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack)
* [thanos](https://github.com/bitnami/charts/tree/master/bitnami/thanos) (to support multicluster monitoring)
* [loki](https://github.com/grafana/helm-charts/tree/main/charts/loki)
* [loki-distributed](https://github.com/grafana/helm-charts/tree/main/charts/loki-distributed)
* [promtail](https://github.com/grafana/helm-charts/tree/main/charts/promtail)

# Installation
Prerequisites
* [Helm3](https://helm.sh/)
* For production environment we recommend (based on our experience) a kubernetes cluster with at least 2 worker nodes and 4 GiB RAM per node or more.


dNation Kubernetes Monitoring Stack umbrella chart is hosted in the [dNation helm repository](https://artifacthub.io/packages/search?repo=dnationcloud). By default, dNation Kubernetes Monitoring Stack installs Prometheus with Thanos sidecar and Thanos Query. For more details check [Multicluster monitoring support](#multicluster-monitoring-support) section.
```bash
# Add dNation helm repository
helm repo add dnationcloud https://dnationcloud.github.io/helm-hub/
helm repo update

# Install dNation Kubernetes Monitoring Stack (Loki in monolithic mode)
helm install monitoring dnationcloud/dnation-kubernetes-monitoring-stack

# Install dNation Kubernetes Monitoring Stack (Loki in distributed mode with s3-compatible storage)
helm install monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
  -f https://raw.githubusercontent.com/dNationCloud/kubernetes-monitoring-stack/main/chart/values-loki-distributed.yaml \
  --set loki-distributed.loki.storageConfig.aws.s3="<s3 path-style URL with access and secret keys>"
```

Search for `Monitoring` dashboard in the `dNation` directory. The fun starts here :).
If you want to set the `Monitoring` dashboard as a home dashboard follow [here](https://grafana.com/docs/grafana/latest/administration/change-home-dashboard/#set-the-default-dashboard-through-preferences).

For `multi-cluster centralized logging` install monitoring on your workload cluster without Loki, set `loki.enabled: false` in [values.yaml](chart/values.yaml) and also configure `promtail.config.lokiAddress` to send logs to your Loki instance. On your central cluster install it in classic way with `loki.enable: true`.

If you're experiencing issues please read the [documentation](https://dnationcloud.github.io/kubernetes-monitoring/docs/documentation) and [FAQ](https://dnationcloud.github.io/kubernetes-monitoring/helpers/FAQ/).

# Kubernetes support (tested)

||dNation monitoring v1.3|dNation monitoring v1.4|dNation monitoring v2.0|dNation monitoring v2.3|dNation monitoring v2.5|
|-|-|-|-|-|-|
|Kubernetes v1.17|✓|||||
|Kubernetes v1.18|✓|||||
|Kubernetes v1.19|✓|||||
|Kubernetes v1.20|✓|||||
|Kubernetes v1.21||✓|✓|||
|Kubernetes v1.22||✓|✓|✓||
|Kubernetes v1.23||||✓|✓|
|Kubernetes v1.24|||||✓|
|Kubernetes v1.25|||||✓|

# Multicluster monitoring support
This chart supports also setup of multicluster monitoring using Thanos. The deployment architecture follows "observer cluster/workload clusters" pattern, where there is one observer k8s cluster which provides centralized monitoring overview of multiple workload k8s clusters. Helm values files enabling the multicluster monitoring are located inside `multicluster-config/` directory. There are 2 files in total:

- `multicluster-config/observer-values.yaml` - contains config for installation of observer cluster
- `multicluster-config/workload-values.yaml` - contains config for installation of workload cluster(s)

## Architecture

As mentioned earlier, we are using "observer cluster/workload clusters" pattern to implement multicluster monitoring. The full architecture can be seen on following diagram:

![](thanos-deployment-architecture.svg)

## Installation

### Observer cluster

Prerequisites
* [Cert-manager](https://cert-manager.io/)


```shell
helm --kube-context <observer-kubeconfig-context> \
install --timeout 5m \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/observer-values.yaml \
-f <custom-observer-values-sample.yaml>
```

`custom-observer-values-sample.yaml` file contains custom, user managed config values for observer cluster. Example of the file:

```yaml
thanosStorage:
  config: |-
    type: S3
    config:
      endpoint: "<url-of-the-S3-endpoint>"
      bucket: "<observer-bucket-name>"
      access_key: "<access-key>"
      secret_key: "<secret-key>"

thanosQueryEnvoySidecar:
  config:
   - name: <envoy-name>
     listenPort: 10001
     queryUrl: <url of exposed query component on remote workload cluster>
     queryPort: <port of exposed query component on remote workload cluster>
     tls:
       certificate_chain: /certs/tls.crt
       private_key: /certs/tls.key
       trusted_ca: /certs/ca.crt

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
- `thanosQueryEnvoySidecar.config` field that contains configuration of the thanos query envoy sidecar in the observer cluster.
- `kube-prometheus-stack.prometheus.prometheusSpec.externalLabels.cluster` field contains prometheus external label uniquely identifying observer cluster metrics.
- `kube-prometheus-stack.grafana.ingress.hosts` field contains list of hostnames on which the  observer grafana will be available
- `thanos.query.stores` field contains list of endpoints representing workload clusters. Everytime new workload cluster is introduced, its needs to be added to this list, so observer cluster knows about it.

You must also generate CA and this will be trusted by the workload clusters ingress, here is how:

1. Create self-signed Issuer in order to create a root CA certificate(`certs/issuer-ss.yaml`)
2. Generate a CA Certificate used to sign certificate(`certs/ca.yaml`)
3. Create an Issuer that uses the above generated CA certificate to issue certs(`certs/issuer-ca.yaml`)
4. Finally, generate a serving certificate for server and client(`certs/server-certificate.yaml`, `certs/client-certificate.yaml`)
5. Create secret for envoy (`certs/client-secret.yaml`)

### Workload cluster

```shell
helm --kube-context <workload-N-kubeconfig-context> \
install --timeout 5m \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/workload-values.yaml \
-f <custom-workload-values-sample.yaml>
```

`custom-workload-values-sample.yaml` file contains custom, user managed config values for workload cluster. Each workload cluster should have its own file. Example of the file:

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

As a last step you have to add exposed thanos-query endpoint of workload cluster into `thanos.query.stores` list in your `custom-observer-values-sample.yaml` file, so your observer cluster knows about newly created workload cluster.
Point thanos query component to the envoy listener port, so thanos query component will then query your workload cluster and aggregate the query results. After that, your `custom-observer-values-sample.yaml` file should look like this:

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
   - dnssrv+_http-[envoy-name]._tcp.thanos-query-envoy.[namespace].svc.cluster.local
```

Thanos sidecar in workload clusters is published with an Ingress object with TLS client auth. To trust the observer cluster CA you need to create following two secerets:

1. Create thanos-ca-secret, where `ca.crt` in data field is coppied from server-secret created by `certs/server-certificate.yaml` on observer cluster
2. Create `certs/server-secret.yaml`, where fields `ca.crt`, `tls.crt`, `tls.key` are copied from server-secret created by `certs/server-certificate.yaml` on observer cluster

After you added new workload cluster endpoint into `custom-observer-values-sample.yaml` file, update the configuration of your observer cluster:

```shell
helm --kube-context <observer-kubeconfig-context> \
upgrade --timeout 5m --install \
--namespace monitoring --create-namespace \
dnation-kubernetes-monitoring-stack \
dnationcloud/dnation-kubernetes-monitoring-stack \
-f multicluster-config/observer-values.yaml \
-f <custom-observer-values-sample.yaml>
```
# Openshift support
## Tested versions

||dNation monitoring v1.3|dNation monitoring v1.4|dNation monitoring v2.0|dNation monitoring v2.3|
|-|-|-|-|-|
|Openshift v4.7||||✓|
## Installation
To install the chart on an openshift cluster, use additional [values for openshift](/chart/values-openshift.yaml)
```shell
 helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack -f chart/values-openshift.yaml
```
Multi cluster setup with openshift as a workload cluster
```shell
helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
-f chart/values-openshift.yaml \
-f multicluster-config/workload-values-openshift.yaml \
-f <custom-workload-values-sample.yaml>
```
Multi cluster setup with openshift as an observer cluster
```shell
helm upgrade --install -n dnation-monitoring dnation-monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
-f chart/values-openshift.yaml \
-f multicluster-config/observer-values-openshift.yaml \
-f <custom-observer-values-sample.yaml>
```
## Security context constraints (SCC)
The chart creates its own [SCC](https://docs.openshift.com/container-platform/3.11/admin_guide/manage_scc.html). If you want to use an existing SCC from your cluster, set `openshift.existingSecurityContextConstraints: <scc-name>`.
```yaml
# Example values
openshift:
  enabled: true
  # If null, create new scc
  existingSecurityContextConstraints: <scc-name>
```
## Service Accounts
It is required that all default service accounts are disabled. New service accounts must be then created and linked in values
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
Service accounts are already configured in [values-openshift.yaml](/chart/values-openshift.yaml) for single cluster setup. For multicluster setup, `openshift.serviceAccounts` list is overriden in [workload-values-openshift.yaml](/multicluster-config/workload-values-openshift.yaml) resp.[workload-values-openshift.yaml](/multicluster-config/workload-values-openshift.yaml), so only relevant sevice accounts are created.
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
This script is also in `helpers/openshift_etcd.sh`
## Configuration

Further configuration of openshift monitoring is possible, see [values-openshift.yaml](/chart/values-openshift.yaml).
# SSL Exporter
Our monitoring stack contains a helmchart for [ribbybibby/ssl_exporter](https://github.com/ribbybibby/ssl_exporter) as an optional component
## Configuration
Enable ssl-exporter  by adding `--set ssl-exporter.enabled=true` flag to the `helm` command, or enable it in values file.
You can further configure ssl-exporter with values file

```yaml
ssl-exporter:
  enabled: false
  serviceMonitor:
  #  We can enable the service monitor, because we have prometheus in our monitoring stack
    enabled: true
  # Configure external URLs to scrape
    externalTargets:
    - example.com:443
  # Configure  kubernetes secrets to scrape
    secretTargets:
  # e.g. all secrets across all namespaces
    - "*/*"
  # Certificate files on control plane nodes
    fileTargets:
  # Included in default values of ssl-exporter helm chart
    - "/etc/kubernetes/pki/**/*.crt"
  # Certificates within kubeconfig files
    kubeconfigTargets:
  # Included in default values of ssl-exporter helm chart
    - /etc/kubernetes/admin.conf
```

More information about configuration is in the [helmchart repo](https://github.com/dNationCloud/ssl-exporter)
and [ribbybibby/ssl_exporter](https://github.com/ribbybibby/ssl_exporter) repo.


# Contribution guidelines
If you want to contribute, please read following:
1. [Contribution Guidelines](CONTRIBUTING.md)
1. [Code of Conduct](CODE_OF_CONDUCT.md)
1. [How To](helpers/README.md) simplify your local development

We use GitHub issues to manage requests and bugs.

# Commercial support
This project has been developed, maintained and used in production by professionals to simplify their day-to-day monitoring tasks and reduce incident reaction time.

Commercial support is available, including 24/7, please [contact us](mailto:cloud@dNation.cloud?subject=Request%20for%20commercial%20support%20of%20dNation%20Kubernetes%20Monitoring).
