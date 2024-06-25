# Prometheus Blackbox Exporter

Our monitoring stack contains a helm chart for [prometheus-blackbox-exporter](https://github.com/prometheus-community/helm-charts/tree/main/charts/prometheus-blackbox-exporter) as an optional component.

## Configuration

Enable prometheus-blackbox-exporter by adding `--set prometheus-blackbox-exporter.enabled=true` flag to the `helm` command, or enable it in values file.
You can further configure prometheus-blackbox-exporter with values file, e.g.:

```yaml
prometheus-blackbox-exporter:
  enabled: true
  serviceMonitor:
    targets:
    - name: dnation-cloud
      url: https://dnation.cloud/
# enable also dashboards
dnation-kubernetes-monitoring:
  blackboxMonitoring:
    enabled: true
```
