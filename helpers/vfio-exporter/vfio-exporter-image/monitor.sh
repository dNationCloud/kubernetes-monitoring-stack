#!/bin/sh
while true; do
  # Count unique processes using VFIO devices
  COUNT=$(fuser /dev/vfio/[0-9]* 2>/dev/null | wc -w)
  TOTAL_COUNT=$(ls /dev/vfio/[0-9]* 2>/dev/null | wc -w)

  # Format as a Prometheus metric
  echo "node_vfio_gpu_in_use_count $COUNT" > /tmp/textfile_collector/gpu_metrics.prom.tmp
  echo "node_vfio_gpu_total_count $TOTAL_COUNT" >> /tmp/textfile_collector/gpu_metrics.prom.tmp

  # Atomic move to prevent Node Exporter from reading a partial file
  mv /tmp/textfile_collector/gpu_metrics.prom.tmp /tmp/textfile_collector/gpu_metrics.prom
  sleep 30
done
