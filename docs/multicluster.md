# Multi cluster monitoring support
This chart supports also setup of multi cluster monitoring using Thanos. The deployment architecture follows
"observer cluster/workload clusters" pattern, where there is one observer k8s cluster which provides centralized
monitoring overview of multiple workload k8s clusters. Helm values files enabling the multi cluster monitoring are
located inside `helpers/multicluster-config/` directory. There are 2 files in total:

- `helpers/multicluster-config/observer-values.yaml` - contains config for installation of observer cluster
- `helpers/multicluster-config/workload-values.yaml` - contains config for installation of workload cluster(s)

For `multi-cluster centralized logging` install monitoring on your workload cluster without Loki, set `loki.enabled: false`
in [values.yaml](../chart/values.yaml) and also configure `promtail.config.lokiAddress` to send logs to your Loki instance.
On your central cluster install it in classic way with `loki.enable: true`.

## Architecture

As mentioned earlier, we are using "observer cluster/workload clusters" pattern to implement multi cluster monitoring.
The full architecture can be seen on following diagram:

![](./images/thanos-deployment-architecture.svg)

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
  -f helpers/multicluster-config/observer-values.yaml \
  -f <custom-observer-values-sample.yaml>
```

`custom-observer-values-sample.yaml` file is optional and could contain custom, user managed config values for observer
cluster. Example of the file:

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

thanos:
  query:
    stores: []
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
  -f helpers/multicluster-config/workload-values.yaml \
  -f <custom-workload-values-sample.yaml>
```

`custom-workload-values-sample.yaml` file is optional and cloud contain custom, user managed config values for workload
cluster. Each workload cluster should have its own file. Example of the file:

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

As a last step you have to add exposed thanos-query endpoint of workload cluster into `thanos.query.stores` list in your
`custom-observer-values-sample.yaml` file, so your observer cluster knows about newly created workload cluster.
Point thanos query component to the envoy listener port, so thanos query component will then query your workload cluster
and aggregate the query results. After that, your `custom-observer-values-sample.yaml` file should look like this:

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

thanos:
  query:
    stores:
    - dnssrv+_http-[envoy-name]._tcp.thanos-query-envoy.[namespace].svc.cluster.local
```

Thanos sidecar in workload clusters is published with an Ingress object with TLS client auth. To trust the observer
cluster CA you need to create following two secrets:

1. Create thanos-ca-secret, where `ca.crt` in data field is coppied from server-secret created by `certs/server-certificate.yaml` on observer cluster
2. Create `certs/server-secret.yaml`, where fields `ca.crt`, `tls.crt`, `tls.key` are copied from server-secret created by `certs/server-certificate.yaml` on observer cluster

After you added new workload cluster endpoint into `custom-observer-values-sample.yaml` file, update the configuration
of your observer cluster:

```shell
helm --kube-context <observer-kubeconfig-context> \
  upgrade --timeout 5m --install \
  --namespace monitoring --create-namespace \
  dnation-kubernetes-monitoring-stack \
  dnationcloud/dnation-kubernetes-monitoring-stack \
  -f multicluster-config/observer-values.yaml \
  -f <custom-observer-values-sample.yaml>
```
