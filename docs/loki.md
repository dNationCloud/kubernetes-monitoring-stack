# Loki

## loki-distributed

This chart is deprecated and replaced by [loki](https://github.com/grafana/loki/tree/main/production/helm/loki) helm chart.
Find the deprecated values in `helpers/loki/values-loki-distributed.yaml`

Loki helm chart is the only helm chart you should use for loki helm deployment. It supports loki deployment in monolithic, scalable
and even [distributed mode](https://grafana.com/docs/loki/next/setup/install/helm/install-microservices/).

We recommend use the loki helm chart for all fresh installations. If you already use loki-distributed helm chart, check
the migration [guide](https://grafana.com/docs/loki/latest/setup/migrate/migrate-from-distributed/).
