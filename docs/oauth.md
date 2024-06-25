# OAUTH

This guide set up oauth2 for Thanos Query UI and Alertmanager UI with GitHub OAUTH integration, ref: https://kubernetes.github.io/ingress-nginx/examples/auth/oauth-external-auth/.

To use it, inspect `helpers/oauth/oauth2-proxy.yaml` and modify it according to your needs.
You want to change at least these:
- OAUTH2_PROXY_CLIENT_ID
- OAUTH2_PROXY_CLIENT_SECRET
- OAUTH2_PROXY_COOKIE_SECRET
- ingress host

Then deploy oauth2-proxy as follows:
```bash
kubectl apply -f helpers/oauth/oauth2-proxy.yaml
```

Adjust and incorporate configuration snippets below into the monitoring helm values:
- Thanos Query
  - It is exposed via ingress on https://<domain>/thanos
  - Modified with `--web.external-prefix=thanos` extra flag
  - Thanos ruler query endpoint and grafana datasource url need to be modified as well
```yaml
thanos:
  query:
    ## Adjust and apply if you want to expose Thanos Query UI via HTTPS endpoint `https://<domain>/thanos`
    ## TLS termination should be defined via grafana ingress.
    ingress:
      enabled: true
      annotations:
        nginx.ingress.kubernetes.io/auth-url: "https://$host/oauth2/auth"
        nginx.ingress.kubernetes.io/auth-signin: "https://$host/oauth2/start?rd=$escaped_request_uri"
      ingressClassName: nginx
      hostname: REPLACE ME
      path: /thanos
    extraFlags:
    - --web.external-prefix=thanos
grafanaDatasourcesAsConfigMap:
  cluster-metrics:
  - name: thanos
    isDefault: true
    type: prometheus
    access: proxy
    url: http://thanos-query-frontend:9090/thanos
kube-prometheus-stack:
  thanosRuler:
    thanosRulerSpec:
      queryEndpoints:
      - http://thanos-query:9090/thanos
```
- Alertmanager
  - It is exposed via ingress on https://<domain>/alertmanager
  - Modified with `routePrefix: /alertmanager` alertmanagerSpec
  - The Thanos ruler url needs to be modified as well
```yaml
kube-prometheus-stack:
  alertmanager:
    ## Adjust and apply if you want to expose Alertmanager UI via HTTPS endpoint `https://<domain>/alertmanager`
    ## TLS termination should be defined via grafana ingress.
    ingress:
      enabled: true
      annotations:
        nginx.ingress.kubernetes.io/auth-url: "https://$host/oauth2/auth"
        nginx.ingress.kubernetes.io/auth-signin: "https://$host/oauth2/start?rd=$escaped_request_uri"
      ingressClassName: nginx
      hosts:
      - REPLACE ME
      paths:
      - /alertmanager
    alertmanagerSpec:
     routePrefix: /alertmanager
  thanosRuler:
    thanosRulerSpec:
      alertmanagersUrl:
      - <alertmanagerUrl>/alertmanager
```
