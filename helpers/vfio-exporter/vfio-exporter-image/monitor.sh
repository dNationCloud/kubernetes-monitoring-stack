#!/bin/sh
# Read-only connection to the host libvirt (socket mounted from /run/libvirt)
VIRSH="virsh -r -c qemu:///system"

while true; do
  TOTAL_COUNT=$(ls /dev/vfio/[0-9]* 2>/dev/null | wc -w)
  COUNT=0

  # Count PCI devices assigned to libvirt domains, including shut off ones,
  # since a stopped VM still holds its GPU. Nodes without VFIO devices skip libvirt.
  if [ "$TOTAL_COUNT" -gt 0 ]; then
    if ! DOMAINS=$($VIRSH list --all --name); then
      echo "Cannot connect to libvirt, metrics not updated" >&2
      sleep 30
      continue
    fi
    COUNT=$(for d in $DOMAINS; do
      $VIRSH dumpxml "$d" | sed -n "/<hostdev .*type='pci'/,/<\/hostdev>/p" | grep "<address domain="
    done | sort -u | wc -l)
  fi

  # Format as a Prometheus metric
  echo "node_vfio_gpu_in_use_count $COUNT" > /tmp/textfile_collector/gpu_metrics.prom.tmp
  echo "node_vfio_gpu_total_count $TOTAL_COUNT" >> /tmp/textfile_collector/gpu_metrics.prom.tmp

  # Atomic move to prevent Node Exporter from reading a partial file
  mv /tmp/textfile_collector/gpu_metrics.prom.tmp /tmp/textfile_collector/gpu_metrics.prom
  sleep 30
done
