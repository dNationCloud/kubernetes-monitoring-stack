#!/usr/bin/env bash
#
# Per-guest OOM kill counter for the node_exporter textfile collector.
#
# node_vmstat_oom_kill only says that the OOM killer fired on the node. The
# kernel log also says whom it killed (task_memcg=/qemu.slice/<vmid>.scope or
# /lxc/<vmid>/...), and this script counts those kills per guest.
#
# For a container every killed process is counted. For a VM only the host
# killing the whole VM is visible; kills inside the guest OS need
# node_exporter in the VM.
#
# Each run reads only the kernel log entries since the previous run. The
# cursor and the totals live in one state file that is replaced atomically.
#
# PVE_OOM_DEBUG=1 prints what was found to stderr.

set -euo pipefail

TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
STATE_DIR="${STATE_DIR:-/var/lib/node_exporter/pve-guest-oom}"
VMLIST="${VMLIST:-/etc/pve/.vmlist}"
JOURNALCTL="${JOURNALCTL:-journalctl}"
NODE="${NODE:-${HOSTNAME%%.*}}"

out="${TEXTFILE_DIR}/pve_guest_oom.prom"
state="${STATE_DIR}/state"

if [[ ! -d $TEXTFILE_DIR ]]; then
  echo "textfile directory $TEXTFILE_DIR does not exist" >&2
  exit 1
fi
mkdir -p "$STATE_DIR"

cursor=""
if [[ -r $state ]]; then
  read -r key value <"$state" || true
  [[ ${key:-} == cursor ]] && cursor=${value:-}
fi

# Without a cursor, -k starts at the beginning of the current boot.
journal_args=(-k -q -o cat --no-pager --show-cursor)
[[ -n $cursor ]] && journal_args+=(--after-cursor="$cursor")

trap 'rm -f "${state}.tmp" "${out}.tmp"' EXIT

# A journalctl failure stops the script (pipefail) before any file is
# replaced, so the next run retries from the same cursor.
"$JOURNALCTL" "${journal_args[@]}" | awk \
  -v state="$state" -v vmlist="$VMLIST" -v node="$NODE" \
  -v state_tmp="${state}.tmp" -v out_tmp="${out}.tmp" \
  -v debug="${PVE_OOM_DEBUG:-0}" '
function dbg(msg) { if (debug == 1) print msg > "/dev/stderr" }

# Value of "key": "value" in a .vmlist entry.
function field(rec, key,    s) {
  if (!match(rec, "\"" key "\": *\"[^\"]*\"")) return ""
  s = substr(rec, RSTART, RLENGTH)
  sub(/^"[^"]*": *"/, "", s)
  sub(/"$/, "", s)
  return s
}

BEGIN {
  cursor = ""
  while ((getline line < state) > 0) {
    split(line, f, " ")
    if (f[1] == "cursor") cursor = substr(line, 8)
    else if (f[2] ~ /^[0-9]+$/) kills[f[1]] = f[2] + 0
  }
  close(state)

  # .vmlist holds every guest of the cluster, one per {...} block:
  #   "100": { "node": "pve1", "type": "qemu", "version": 3 }
  guests = 0
  RS = "}"
  while ((getline rec < vmlist) > 0) {
    if (!match(rec, /"[0-9]+": *\{/)) continue
    vmid = substr(rec, RSTART + 1, RLENGTH)
    sub(/".*/, "", vmid)
    type = field(rec, "type")
    if (type != "qemu" && type != "lxc") continue
    id = type "/" vmid
    exists[id] = 1
    guests++
    if (field(rec, "node") == node) local_ids[id] = 1
  }
  close(vmlist)
  RS = "\n"
  if (guests == 0) print "no guests read from " vmlist ", keeping all state" > "/dev/stderr"
  dbg("vmlist: " guests " guests in cluster")
}

/^-- cursor: / { cursor = substr($0, 12); next }

{
  i = index($0, "task_memcg=")
  if (i == 0) next
  path = substr($0, i + 11)
  sub(/[, \t].*/, "", path)

  if (path ~ /^\/qemu\.slice\/[0-9]+\.scope/) {
    vmid = substr(path, 13)
    sub(/\.scope.*/, "", vmid)
    id = "qemu/" vmid
  } else if (path ~ /^\/lxc\/[0-9]+(\/|$)/) {
    vmid = substr(path, 6)
    sub(/\/.*/, "", vmid)
    id = "lxc/" vmid
  } else {
    dbg("kill: " path " -> not a guest, skipped")
    next
  }
  kills[id]++
  dbg("kill: " path " -> " id " (total " kills[id] ")")
}

END {
  # Deleted guests are dropped from the state. Their history stays in Prometheus.
  print "cursor " cursor > state_tmp
  for (id in kills) {
    if (guests > 0 && !(id in exists)) { dbg("pruned: " id); continue }
    print id, kills[id] > state_tmp
    emit[id] = kills[id]
  }
  close(state_tmp)

  # Every guest on this node starts at 0, otherwise increase() misses its first kill.
  for (id in local_ids) if (!(id in emit)) emit[id] = 0

  print "# HELP pve_guest_oom_kills_total Processes in the guest cgroup killed by any OOM killer, as reported by the kernel log." > out_tmp
  print "# TYPE pve_guest_oom_kills_total counter" > out_tmp
  for (id in emit) {
    split(id, p, "/")
    printf "pve_guest_oom_kills_total{id=\"%s\",vmid=\"%s\",type=\"%s\"} %d\n", id, p[2], p[1], emit[id] > out_tmp
  }
  close(out_tmp)
}'

mv "${state}.tmp" "$state"
mv "${out}.tmp" "$out"
