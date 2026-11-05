#!/usr/bin/env bash
#
# CPU time of every guest on every physical CPU, for the node_exporter
# textfile collector.
#
# A small eBPF program (bpftrace) sums, on every context switch, how long the
# task leaving the CPU ran there, keyed by its cgroup and the CPU. All threads
# of a guest are in its cgroup, so the whole guest is counted. Every INTERVAL
# seconds the sums are printed, cleared and added to the totals here.
#
# The cgroup id is the inode of /sys/fs/cgroup/qemu.slice/<vmid>.scope for a
# VM and of /sys/fs/cgroup/lxc/<vmid> and its subdirectories for a container.
#
# Also writes the CPUs each guest is allowed to run on (affinity / cpuset).
# Counters start at 0 when the service starts; a guest's series disappear
# when it stops running on this node.
#
# PVE_CPU_DEBUG=1 prints what was mapped to stderr.

set -euo pipefail

TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
BPFTRACE="${BPFTRACE:-bpftrace}"
CGROUP_ROOT="${CGROUP_ROOT:-/sys/fs/cgroup}"
INTERVAL="${INTERVAL:-60}"
# Map entries are (cgroup, CPU) pairs seen within one interval. When the map
# is full new pairs are not counted, bpftrace then logs a warning.
MAX_MAP_KEYS="${MAX_MAP_KEYS:-65536}"

out="${TEXTFILE_DIR}/pve_guest_cpu.prom"

if [[ ! -d $TEXTFILE_DIR ]]; then
  echo "textfile directory $TEXTFILE_DIR does not exist" >&2
  exit 1
fi

trap 'rm -f "${out}.tmp"' EXIT

# sched_switch runs in the context of the task leaving the CPU: "cgroup" is
# its cgroup and nsecs - @start[cpu] is how long it ran. pid 0 is idle.
program='
config = { max_map_keys = '"$MAX_MAP_KEYS"' }

tracepoint:sched:sched_switch
{
  if (args.prev_pid != 0) {
    $s = @start[cpu];
    if ($s) {
      @ns[cgroup, cpu] += nsecs - $s;
    }
  }
  @start[cpu] = nsecs;
}

interval:s:'"$INTERVAL"'
{
  print(@ns);
  clear(@ns);
  printf("end\n");
}

END { clear(@start); clear(@ns); }
'

# mawk is called explicitly: it is always installed on Debian, and only with
# -W interactive does it handle each line as it arrives instead of waiting
# for a full buffer.
"$BPFTRACE" -q -B line -e "$program" | mawk -W interactive \
  -v cgroot="$CGROUP_ROOT" -v out="$out" -v out_tmp="${out}.tmp" \
  -v debug="${PVE_CPU_DEBUG:-0}" '
function dbg(msg) { if (debug == 1) print msg > "/dev/stderr" }

function first_line(file,    line) {
  line = ""
  if ((getline line < file) <= 0) line = ""
  close(file)
  return line
}

# CPUs the guest may run on: the affinity of the qemu process (inherited by
# all its threads), or the effective cpuset of the container.
function allowed(id, vmid,    pid, file, line, cpus) {
  cpus = ""
  if (id ~ /^qemu\//) {
    pid = first_line("/var/run/qemu-server/" vmid ".pid")
    if (pid == "") return ""
    file = "/proc/" pid "/status"
    while ((getline line < file) > 0)
      if (line ~ /^Cpus_allowed_list:/) { cpus = line; sub(/^[^:]*:[ \t]*/, "", cpus) }
    close(file)
  } else {
    cpus = first_line(cgroot "/lxc/" vmid "/cpuset.cpus.effective")
  }
  return cpus
}

# @ns[3034132, 1]: 37501209
/^@ns\[/ {
  line = $0
  gsub(/[^0-9]+/, " ", line)
  split(line, f, " ")
  ns[f[1], f[2]] += f[3]
  next
}

$0 != "end" { next }

{
  # Running guests and the ids of their cgroups.
  delete cg2id
  delete running
  cmd = "find " cgroot "/qemu.slice " cgroot "/lxc -mindepth 1 -type d -printf \"%i %p\\n\" 2>/dev/null"
  while ((cmd | getline line) > 0) {
    split(line, f, " ")
    path = f[2]
    if (match(path, /\/qemu\.slice\/[0-9]+\.scope$/)) {
      vmid = substr(path, RSTART + 12)
      sub(/\.scope$/, "", vmid)
      id = "qemu/" vmid
    } else if (match(path, /\/lxc\/[0-9]+(\/|$)/)) {
      vmid = substr(path, RSTART + 5)
      sub(/\/.*/, "", vmid)
      id = "lxc/" vmid
    } else continue
    cg2id[f[1]] = id
    running[id] = vmid
  }
  close(cmd)

  mapped = 0; other = 0
  for (k in ns) {
    split(k, p, SUBSEP)
    if (p[1] in cg2id) {
      total[cg2id[p[1]], p[2]] += ns[k] / 1e9
      mapped += ns[k]
    } else other += ns[k]
  }
  delete ns
  dbg(sprintf("guests running: %d, guest CPU %.3f s, host and others %.3f s", length(running), mapped / 1e9, other / 1e9))

  # A guest that no longer runs here starts from 0 when it comes back.
  for (k in total) {
    split(k, p, SUBSEP)
    if (!(p[1] in running)) { dbg("dropped: " p[1]); delete total[k] }
  }

  print "# HELP pve_guest_cpu_seconds_total CPU time the guest (all its threads) spent on each physical CPU of the node." > out_tmp
  print "# TYPE pve_guest_cpu_seconds_total counter" > out_tmp
  for (k in total) {
    split(k, p, SUBSEP)
    split(p[1], g, "/")
    printf "pve_guest_cpu_seconds_total{id=\"%s\",vmid=\"%s\",type=\"%s\",cpu=\"%s\"} %.6f\n", p[1], g[2], g[1], p[2], total[k] > out_tmp
  }

  print "# HELP pve_guest_cpu_affinity_info Physical CPUs the guest is allowed to run on (affinity of a VM, cpuset of a container)." > out_tmp
  print "# TYPE pve_guest_cpu_affinity_info gauge" > out_tmp
  for (id in running) {
    cpus = allowed(id, running[id])
    if (cpus == "") continue
    split(id, g, "/")
    printf "pve_guest_cpu_affinity_info{id=\"%s\",vmid=\"%s\",type=\"%s\",cpus=\"%s\"} 1\n", id, g[2], g[1], cpus > out_tmp
  }
  close(out_tmp)

  if (system("mv \"" out_tmp "\" \"" out "\"") != 0) exit 1
}'
