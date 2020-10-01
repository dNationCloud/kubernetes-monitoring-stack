{{/*
Helper variables inspired by kube-prometheus-stack chart
https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
*/}}

{{/* Create a default monitoring name */}}
{{- define "monitoring.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 50 | trimSuffix "-" -}}
{{- end }}

{{/*
Create a default monitoring fully qualified app name
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
The components in this chart create additional resources that expand the longest created name strings.
The longest name that gets created adds and extra 37 characters, so truncation should be 63-35=26.
*/}}
{{- define "monitoring.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 26 | trimSuffix "-" -}}
{{- else -}}
{{- .Release.Name | trunc 26 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "host.expr.overall.cpu" -}}
round((1 - (avg(irate(node_cpu_seconds_total{job=~"{{ default ".*" .jobName }}",mode="idle"}[5m]) * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename) )) * 100)
{{- end }}

{{- define "host.expr.overall.ram" -}}
round((1 - sum by (job, nodename) (node_memory_MemAvailable_bytes{job=~"{{ default ".*" .jobName }}"} * on(instance) group_left(nodename) (node_uname_info)) / sum by (job, nodename) (node_memory_MemTotal_bytes{job=~"{{ default ".*" .jobName }}"} * on(instance) group_left(nodename) (node_uname_info))) * 100)
{{- end }}

{{- define "host.expr.overall.disk" -}}
round((sum(node_filesystem_size_bytes{job=~"{{ default ".*" .jobName }}", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{job=~"{{ default ".*" .jobName }}", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) / (sum(node_filesystem_size_bytes{job=~"{{ default ".*" .jobName }}", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) - sum(node_filesystem_free_bytes{job=~"{{ default ".*" .jobName }}", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device) + sum(node_filesystem_avail_bytes{job=~"{{ default ".*" .jobName }}", device!="rootfs"} * on(instance) group_left(nodename) (node_uname_info)) by (job, nodename, device)) * 100)
{{- end }}

{{- define "host.expr.overall.network" -}}
sum(rate(node_network_transmit_errs_total{job=~"{{ default ".*" .jobName }}", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"} [5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename) + sum(rate(node_network_receive_errs_total{job=~"{{ default ".*" .jobName }}", device!~"lo|veth.+|docker.+|flannel.+|cali.+|cbr.|cni.+|br.+"}[5m]) * on(instance) group_left(nodename) (node_uname_info) ) by (job, nodename)
{{- end }}
