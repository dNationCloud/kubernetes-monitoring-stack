{{/*
Generate listeners section for workload clusters in envoy config
*/}}
{{- define "envoy.listeners" -}}
    {{- range $ -}}
      {{- include "envoy.listener" . -}}
      {{- printf "\n" -}}
    {{- end -}}
{{- end -}}

{{/*
Generate clusters section for workload clusters in envoy config
*/}}
{{- define "envoy.clusters" -}}
    {{- range $ }}
      {{- include "envoy.cluster" . -}}
      {{- printf "\n" -}}
    {{- end -}}
{{- end -}}

{{/*
Generate listener section for 1 workload cluster in envoy config
*/}}
{{- define "envoy.listener" -}}
- name: {{ $.name }}-listener
  address:
    socket_address:
      address: 0.0.0.0
      port_value: {{ $.listenPort }}
  filter_chains:
  - filters:
    - name: envoy.http_connection_manager
      typed_config:
        "@type": type.googleapis.com/envoy.extensions.filters.network.http_connection_manager.v3.HttpConnectionManager
        codec_type: AUTO
        access_log:
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
            log_format:
              text_format: |
                [%START_TIME%] "%REQ(:METHOD)% %REQ(X-ENVOY-ORIGINAL-PATH?:PATH)% %PROTOCOL%"
                %RESPONSE_CODE% %RESPONSE_FLAGS% %RESPONSE_CODE_DETAILS% %BYTES_RECEIVED% %BYTES_SENT% %DURATION%
                %RESP(X-ENVOY-UPSTREAM-SERVICE-TIME)% "%REQ(X-FORWARDED-FOR)%" "%REQ(USER-AGENT)%"
                "%REQ(X-REQUEST-ID)%" "%REQ(:AUTHORITY)%" "%UPSTREAM_HOST%" "%UPSTREAM_TRANSPORT_FAILURE_REASON%"\n
        - name: envoy.access_loggers.file
          typed_config:
            "@type": type.googleapis.com/envoy.extensions.access_loggers.file.v3.FileAccessLog
            path: /dev/stdout
        stat_prefix: ingress_http
        route_config:
          name: local_route
          virtual_hosts:
          - name: local_service
            domains: ["*"]
            routes:
            - match:
                prefix: "/"
              route:
                cluster: {{ $.name }}
                retry_policy:
                  retry_on: 5xx
                  num_retries: 10
                host_rewrite_literal: {{ $.queryUrl }}:{{ $.queryPort }}
        http_filters:
        - name: envoy.filters.http.router
{{- end -}}

{{/*
Generate cluster section for 1 workload cluster in envoy config
*/}}
{{- define "envoy.cluster" -}}
- name: {{ $.name }}
  connect_timeout: 30s
  {{- if $.maxRequestsPerConnection }}
  max_requests_per_connection: {{ $.maxRequestsPerConnection }}
  {{- end }}
  type: LOGICAL_DNS
  http2_protocol_options: {}
  dns_lookup_family: V4_ONLY
  lb_policy: ROUND_ROBIN
  load_assignment:
    cluster_name: {{ $.name }}
    endpoints:
      - lb_endpoints:
        - endpoint:
            address:
              socket_address:
                address: {{ $.queryUrl }}
                port_value: {{ $.queryPort }}
  {{- if $.tls }}
  transport_socket:
    name: envoy.transport_sockets.tls
    typed_config:
      "@type": type.googleapis.com/envoy.extensions.transport_sockets.tls.v3.UpstreamTlsContext
      common_tls_context:
        tls_certificates:
          - certificate_chain:
              filename: {{ $.tls.certificate_chain }}
            private_key:
              filename: {{ $.tls.private_key }}
        validation_context:
          trusted_ca:
            filename: {{ $.tls.trusted_ca }}
        alpn_protocols:
        - h2
      sni: {{ $.queryUrl }}
  {{- end -}}
{{- end -}}
