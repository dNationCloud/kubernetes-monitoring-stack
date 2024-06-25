# Alertmanager notifications to the Matrix chat

This page contains instructions on how to enable the Alertmanager to Matrix chat notifications in the Monitoring solution. 

Project https://github.com/metio/matrix-alertmanager-receiver is used for forwarding alerts to a Matrix room.

To use it, fill your matrix credentials in `helpers/matrix-alertmanager/matrix-alertmanager-receiver.yaml` ConfigMap and deploy it:
```bash
kubectl apply -f helpers/matrix-alertmanager/matrix-alertmanager-receiver.yaml
```

You can modify other settings according to the mentioned project [docs](https://github.com/metio/matrix-alertmanager-receiver)
in the ConfigMap.

Adjust and incorporate configuration snippet below into the monitoring helm values:
```yaml
kube-prometheus-stack:
  alertmanager:
    config:
      route:
        receiver: 'matrix-notifications'
        group_by: ['alertname', 'job', 'severity']
        repeat_interval: 24h
        routes:
        - receiver: 'null'
          match:
            alertname: Watchdog
      receivers:
      - name: 'null'
      - name: 'matrix-notifications'
        webhook_configs:
        - url: "http://matrix-alertmanager-receiver:3000/alerts/alert-room"
```