#!/usr/bin/env bash
#
# Corosync health metrics for the node_exporter textfile collector.
#
# Reads quorum, members, per-link state and latency, token loss, retransmits,
# token round time and backlog from corosync-quorumtool and corosync-cmapctl.
# Nodes, names and links are taken from the running cluster.
#
# Links are reported as seen from this node; the link to itself is skipped.
# If corosync does not answer, only corosync_up 0 is written, so a stale
# quorum state is never shown.
#
# PVE_COROSYNC_DEBUG=1 prints the raw command output to stderr.

set -uo pipefail

TEXTFILE_DIR="${TEXTFILE_DIR:-/var/lib/node_exporter/textfile}"
CMAPCTL="${CMAPCTL:-corosync-cmapctl}"
QUORUMTOOL="${QUORUMTOOL:-corosync-quorumtool}"

out="${TEXTFILE_DIR}/pve_corosync.prom"

if [[ ! -d $TEXTFILE_DIR ]]; then
  echo "textfile directory $TEXTFILE_DIR does not exist" >&2
  exit 1
fi

tmp="${out}.tmp"
trap 'rm -f "$tmp"' EXIT

write_down() {
  {
    echo '# HELP corosync_up Whether corosync could be queried (1) or not (0).'
    echo '# TYPE corosync_up gauge'
    echo 'corosync_up 0'
  } >"$tmp"
  mv "$tmp" "$out"
  echo "corosync could not be queried: $1" >&2
  exit 1
}

# quorumtool exits non-zero when the cluster is not quorate, so its output is
# checked instead of the exit code.
quorum=$("$QUORUMTOOL" -s -p 2>&1)
grep -q '^Quorate:' <<<"$quorum" || write_down "corosync-quorumtool: ${quorum//$'\n'/ }"

nodelist=$("$CMAPCTL" nodelist 2>&1) || write_down "corosync-cmapctl nodelist: $nodelist"
stats=$("$CMAPCTL" -m stats 2>&1) || write_down "corosync-cmapctl -m stats: $stats"
totem=$("$CMAPCTL" runtime.config.totem.token 2>&1) || write_down "corosync-cmapctl runtime.config.totem.token: $totem"

if [[ ${PVE_COROSYNC_DEBUG:-0} == 1 ]]; then
  printf '%s\n' "--- quorum" "$quorum" "--- nodelist" "$nodelist" "--- totem" "$totem" >&2
fi

# All sources go to one awk run, separated by @@section lines.
{
  echo '@@quorum';   printf '%s\n' "$quorum"
  echo '@@nodelist'; printf '%s\n' "$nodelist"
  echo '@@totem';    printf '%s\n' "$totem"
  echo '@@stats';    printf '%s\n' "$stats" | grep -E '^stats\.(knet\.node|srp\.)'
} | awk '
# cmapctl lines look like "key (type) = value".
function cmap_value(line) { sub(/^[^=]*= /, "", line); return line }
function cmap_key(line)   { sub(/ \(.*$/, "", line); return line }
function esc(s) { gsub(/\\/, "\\\\", s); gsub(/"/, "\\\"", s); return s }
function help(name, type, text) {
  printf "# HELP %s %s\n# TYPE %s %s\n", name, text, name, type
}

/^@@/ { section = substr($0, 3); next }

# quorum
section == "quorum" && /^Node ID:/          { local_id = $3 }
section == "quorum" && /^Quorate:/          { quorate = ($2 == "Yes") }
section == "quorum" && /^Expected votes:/   { votes["expected"] = $3 }
section == "quorum" && /^Highest expected:/ { votes["highest_expected"] = $3 }
section == "quorum" && /^Total votes:/      { votes["total"] = $3 }
section == "quorum" && /^Quorum:/           { votes["quorum"] = $2 }

# Member table: columns are found by header name, as -p adds a Qdevice column.
section == "quorum" && $1 == "Nodeid" && /Votes/ {
  in_members = 1
  for (i = 1; i <= NF; i++) col[$i] = i
  next
}
section == "quorum" && in_members && $1 ~ /^[0-9]+$/ {
  id = $1
  member_votes[id] = $(col["Votes"])
  name = ""
  if (col["Name"] > 0) for (i = col["Name"]; i <= NF; i++) if ($i != "(local)") name = name (name == "" ? "" : " ") $i
  member_name[id] = name
  next
}

# nodelist.node.<pos>.name and .nodeid
section == "nodelist" && /^nodelist\.node\.[0-9]+\.(name|nodeid) / {
  split(cmap_key($0), k, ".")
  if (k[4] == "name")   pos_name[k[3]] = cmap_value($0)
  if (k[4] == "nodeid") pos_id[k[3]]   = cmap_value($0)
  next
}

# effective token timeout
section == "totem" && /^runtime\.config\.totem\.token / { token_ms = cmap_value($0) }

# stats.knet.node<id>.link<n>.<field> and stats.srp.<field>
section == "stats" && /^stats\.knet\.node/ {
  split(cmap_key($0), k, ".")
  peer = substr(k[3], 5); link = substr(k[4], 5)
  knet[peer SUBSEP link SUBSEP k[5]] = cmap_value($0)
  links[peer SUBSEP link] = 1
  next
}
section == "stats" && /^stats\.srp\./ {
  split(cmap_key($0), k, ".")
  srp[k[3]] = cmap_value($0)
  next
}

END {
  # Node name: nodelist, else quorumtool, else the node id.
  for (p in pos_id) if (pos_name[p] != "") id_name[pos_id[p]] = pos_name[p]
  for (id in member_name) if (!(id in id_name) && member_name[id] != "") id_name[id] = member_name[id]

  help("corosync_up", "gauge", "Whether corosync could be queried (1) or not (0).")
  print "corosync_up 1"

  help("corosync_quorate", "gauge", "Whether the cluster has quorum (1) or not (0).")
  print "corosync_quorate " (quorate ? 1 : 0)

  help("corosync_quorum_votes", "gauge", "Votequorum votes: expected, highest_expected, total (present now) and quorum (needed).")
  for (t in votes) printf "corosync_quorum_votes{type=\"%s\"} %s\n", t, votes[t]

  help("corosync_member_votes", "gauge", "Votes of each node that is currently a member of the cluster.")
  for (id in member_votes) {
    name = (id in id_name) ? id_name[id] : id
    printf "corosync_member_votes{node_id=\"%s\",node=\"%s\",local=\"%s\"} %s\n", id, esc(name), (id == local_id ? "true" : "false"), member_votes[id]
  }

  help("corosync_link_connected", "gauge", "Whether the knet link to the peer node is up (1) or down (0).")
  help("corosync_link_down_total", "counter", "Times the knet link to the peer node went down.")
  help("corosync_link_latency_seconds", "gauge", "Round-trip time to the peer node, averaged by knet over its last ping samples.")
  for (pl in links) {
    split(pl, x, SUBSEP); peer = x[1]; link = x[2]
    if (peer == local_id) continue
    lbl = sprintf("peer_id=\"%s\",peer=\"%s\",link=\"%s\"", peer, esc((peer in id_name) ? id_name[peer] : peer), link)
    conn[lbl] = knet[peer, link, "connected"]
    down[lbl] = knet[peer, link, "down_count"]
    # Skip latency of a down link (knet keeps the old value) or one without samples.
    if (knet[peer, link, "connected"] == 1 && knet[peer, link, "latency_samples"] > 0) lat[lbl] = knet[peer, link, "latency_ave"] / 1000000
  }
  for (l in conn) printf "corosync_link_connected{%s} %s\n", l, conn[l]
  for (l in down) printf "corosync_link_down_total{%s} %s\n", l, down[l]
  for (l in lat)  printf "corosync_link_latency_seconds{%s} %.6f\n", l, lat[l]

  help("corosync_token_lost_total", "counter", "Times the totem token was lost, by the protocol state it was lost in.")
  for (s in srp) if (s ~ /_token_lost$/) {
    state = s; sub(/_token_lost$/, "", state)
    printf "corosync_token_lost_total{state=\"%s\"} %s\n", state, srp[s]
  }

  if ("mcast_retx" in srp) {
    help("corosync_retransmits_total", "counter", "Totem messages that had to be retransmitted.")
    print "corosync_retransmits_total " srp["mcast_retx"]
  }

  if ("mtt_rx_token" in srp) {
    help("corosync_token_round_time_seconds", "gauge", "Mean time between two consecutive token receives (token round time).")
    printf "corosync_token_round_time_seconds %.3f\n", srp["mtt_rx_token"] / 1000
  }

  if ("avg_backlog_calc" in srp) {
    help("corosync_backlog", "gauge", "Average number of totem messages waiting to be sent.")
    print "corosync_backlog " srp["avg_backlog_calc"]
  }

  if (token_ms != "") {
    help("corosync_token_timeout_seconds", "gauge", "Effective totem token timeout; token loss is declared after this long without a token.")
    printf "corosync_token_timeout_seconds %.3f\n", token_ms / 1000
  }
}' >"$tmp" || write_down "parsing failed"

mv "$tmp" "$out"
trap - EXIT
