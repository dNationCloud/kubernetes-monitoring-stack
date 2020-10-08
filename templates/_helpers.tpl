/*
Helper variables
*/

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
