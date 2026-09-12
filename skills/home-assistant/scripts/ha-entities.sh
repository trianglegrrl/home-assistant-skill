#!/usr/bin/env bash
# Usage: ha-entities.sh [--domain light|switch|lock|climate|...] [--match TEXT] [--json]
# Lists entities with state and friendly name. Hides diagnostic noise unless --all.
source "$(dirname "$0")/lib.sh"
DOMAIN=""; MATCH=""; JSON=0; ALL=0
while [[ $# -gt 0 ]]; do case "$1" in
  --domain) need_value "$@"; DOMAIN="$2"; shift 2;; --match) need_value "$@"; MATCH="$2"; shift 2;; --json) JSON=1; shift;; --all) ALL=1; shift;;
  *) die "Unknown arg $1";; esac; done
ha_get states | HA_D="$DOMAIN" HA_M="$MATCH" HA_J="$JSON" HA_A="$ALL" python3 -c '
import json, os, sys
d=os.environ["HA_D"]; m=os.environ["HA_M"].lower(); j=os.environ["HA_J"]=="1"; a=os.environ["HA_A"]=="1"
noise=("sun","zone","update","tts","conversation","event","stt","number","select","button","script","automation","persistent_notification","input_boolean")
rows=[]
for e in sorted(json.load(sys.stdin), key=lambda e:e["entity_id"]):
    dom=e["entity_id"].split(".")[0]
    if d and dom!=d: continue
    if not a and not d and dom in noise: continue
    if m and m not in e["entity_id"].lower() and m not in (e["attributes"].get("friendly_name") or "").lower(): continue
    rows.append({"entity_id":e["entity_id"],"state":e["state"],"name":e["attributes"].get("friendly_name",""),"unit":e["attributes"].get("unit_of_measurement","")})
if j: print(json.dumps(rows, indent=1))
else:
    for r in rows: print("%-50s %-16s%-5s %s" % (r["entity_id"], r["state"], r["unit"], r["name"]))
    if not rows: print("(no matching entities)")'
