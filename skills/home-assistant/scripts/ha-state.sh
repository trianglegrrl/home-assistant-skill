#!/usr/bin/env bash
# Usage: ha-state.sh <entity_id or name> [--json]
# Shows one entity's state and its useful attributes.
source "$(dirname "$0")/lib.sh"
[[ $# -ge 1 ]] || die "usage: ha-state.sh <entity or name> [--json]"
Q="$1"; JSON=0; [[ "${2:-}" == "--json" ]] && JSON=1
ID="$(ha_resolve "$Q")"
ha_get "states/$ID" | HA_J="$JSON" python3 -c '
import json, os, sys
e=json.load(sys.stdin); a=e["attributes"]
if os.environ["HA_J"]=="1": print(json.dumps(e, indent=1)); sys.exit()
print("%s: %s%s  (%s)  updated %s" % (e["entity_id"], e["state"], a.get("unit_of_measurement",""), a.get("friendly_name",""), e["last_updated"][:19]))
skip={"friendly_name","icon","attribution","supported_features","entity_picture","unit_of_measurement"}
for k,v in a.items():
    if k in skip: continue
    print("  %s: %s" % (k, v))'
