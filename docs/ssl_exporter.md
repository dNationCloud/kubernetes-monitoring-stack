# SSL Exporter

Our monitoring stack contains a helm chart for [ribbybibby/ssl_exporter](https://github.com/ribbybibby/ssl_exporter) as an optional component.

## Configuration

Enable ssl-exporter by adding `--set ssl-exporter.enabled=true` flag to the `helm` command, or enable it in values file.
You can further configure ssl-exporter with values file:

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

More information about configuration is in the [helmchart repo](https://github.com/dNationCloud/ssl-exporter) and [ribbybibby/ssl_exporter](https://github.com/ribbybibby/ssl_exporter) repository.
