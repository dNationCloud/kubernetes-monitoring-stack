# VFIO GPU exporter

Shows how many GPUs on OpenStack compute nodes are passed through to VMs (bound to `vfio-pci`) and how many of them are taken.

The exporter is a small sidecar container in the node-exporter pod. Every 30 seconds it writes two metrics into the node-exporter [textfile collector](https://github.com/prometheus/node_exporter#textfile-collector):

| Metric | Meaning | How it is counted |
|---|---|---|
| `node_vfio_gpu_total_count` | GPUs on the node available for passthrough | IOMMU groups in `/dev/vfio` |
| `node_vfio_gpu_in_use_count` | GPUs assigned to a VM | PCI devices in the `<hostdev>` of all libvirt domains, **including shut off ones** |

A shut off VM still holds its GPU in Nova, nobody else can get it until the VM is deleted, so it counts as in use.
The exporter talks to the host libvirt read-only: `virsh -r -c qemu:///system` over the socket in `/run/libvirt`.
Nodes without VFIO devices report `0` and never touch libvirt.

## Requirements

- GPUs bound to `vfio-pci` on the compute nodes (`lspci -nnk` shows `Kernel driver in use: vfio-pci`)
- libvirt socket on the host in `/run/libvirt` (`libvirt-sock-ro`)
- node-exporter running privileged, as root

## Install

Add [values-vfio-exporter.yaml](values-vfio-exporter.yaml) to your Helm command:

```bash
helm upgrade --install monitoring dnationcloud/dnation-kubernetes-monitoring-stack \
  -f <your values> \
  -f helpers/vfio-exporter/values-vfio-exporter.yaml
```

Helm does not merge lists from several values files, the last file replaces the whole list. If your values file
already has one of these lists under `prometheus-node-exporter` (`extraArgs`, `sidecars`, `sidecarVolumeMount`,
`sidecarHostVolumeMounts`), copy the entries from `values-vfio-exporter.yaml` into your values file instead of
using it with `-f`.

The image is `ghcr.io/dnationcloud/vfio-exporter`. Use `0.2.0` or newer.

## Dashboard

Enable the `vfioGPU` template for the cluster, it adds the "VFIO GPU" panel to the cluster overview, linked to the
"Vfio GPU Devices" dashboard (in use / total per node):

```yaml
dnation-kubernetes-monitoring:
  clusterMonitoring:
    clusters:
    - name: <cluster>
      apps:
      - name: usage
        description: GPU devices usage
        jobName: vfio-gpu
        templates:
          vfioGPU:
            enabled: true
```

## Build

```bash
docker build -t ghcr.io/dnationcloud/vfio-exporter:<version> helpers/vfio-exporter/vfio-exporter-image
docker push ghcr.io/dnationcloud/vfio-exporter:<version>
```
