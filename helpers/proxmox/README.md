# Proxmox VE helper scripts

Some panels of the Proxmox VE dashboard need metrics that no standard exporter
provides. The scripts in this directory write them to the
[node_exporter textfile collector](https://github.com/prometheus/node_exporter#textfile-collector)
on each Proxmox node. Without them, those panels show **No data**; the rest of
the dashboard works without them.

| script | metrics | dashboard panels |
| --- | --- | --- |
| `pve-guest-oom.sh` | `pve_guest_oom_kills_total` | Guests table (OOM killed by host), Guest OOM kills |
| `pve-corosync.sh` | `corosync_*` | Corosync row |
| `pve-guest-cpu.sh` | `pve_guest_cpu_seconds_total`, `pve_guest_cpu_affinity_info` | Physical cores used by guests |

## Requirements

node_exporter on every node, started with
`--collector.textfile.directory=/var/lib/node_exporter/textfile`.

```bash
mkdir -p /var/lib/node_exporter/textfile
```

## Installation

Run on each Proxmox node as root, from this directory.

OOM kills per guest, from the kernel log once a minute:

```bash
install -m 755 pve-guest-oom.sh /usr/local/bin/pve-guest-oom.sh
install -m 644 pve-guest-oom.service pve-guest-oom.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now pve-guest-oom.timer
```

Corosync quorum, link and token metrics, once a minute:

```bash
install -m 755 pve-corosync.sh /usr/local/bin/pve-corosync.sh
install -m 644 pve-corosync.service pve-corosync.timer /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now pve-corosync.timer
```

Physical CPUs each guest ran on, measured with bpftrace:

```bash
apt-get install -y bpftrace
install -m 755 pve-guest-cpu.sh /usr/local/bin/pve-guest-cpu.sh
install -m 644 pve-guest-cpu.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable --now pve-guest-cpu
```

## Verify

After a minute:

```bash
curl -s localhost:9100/metrics | grep -E '^(pve_guest_oom_kills_total|corosync_up|pve_guest_cpu_seconds_total)'
```
