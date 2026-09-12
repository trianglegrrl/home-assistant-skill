#!/usr/bin/env bash
# Usage: ha-call.sh <domain.service> [--entity <id or name>] [--data '{"json":...}']
# Calls a Home Assistant service and prints the entities it changed with their new state.
# Examples: ha-call.sh light.turn_on --entity "kitchen" --data '{"brightness_pct":40,"color_name":"blue"}'
#           ha-call.sh lock.lock --entity lock.front_door
#           ha-call.sh climate.set_temperature --entity thermostat --data '{"temperature":21}'
source "$(dirname "$0")/lib.sh"
[[ $# -ge 1 && "$1" == *.* ]] || die "usage: ha-call.sh <domain.service> [--entity X] [--data JSON]"
SVC="$1"; shift; ENT=""; DATA="{}"
while [[ $# -gt 0 ]]; do case "$1" in
  --entity) need_value "$@"; ENT="$2"; shift 2;; --data) need_value "$@"; DATA="$2"; shift 2;;
  *) die "Unknown arg $1";; esac; done
python3 -c 'import json,sys; json.loads(sys.argv[1])' "$DATA" 2>/dev/null || die "--data is not valid JSON"
DOMAIN="${SVC%%.*}"; SERVICE="${SVC#*.}"
if [[ -n "$ENT" ]]; then
  # Resolve within the service's domain first (light.* for light.turn_on), then anywhere.
  ID="$(ha_resolve "$ENT" "$DOMAIN" 2>/dev/null || ha_resolve "$ENT")"
  DATA="$(HA_ID="$ID" python3 -c 'import json,os,sys; d=json.loads(sys.argv[1]); d["entity_id"]=os.environ["HA_ID"]; print(json.dumps(d))' "$DATA")"
fi
ha_post "services/$DOMAIN/$SERVICE" "$DATA" | python3 -c '
import json, sys
changed=json.load(sys.stdin)
if not changed: print("Service accepted; no entity state changed (this is normal for some services)."); sys.exit()
for e in changed: print(f"{e[\"entity_id\"]}: {e[\"state\"]}  ({e[\"attributes\"].get(\"friendly_name\",\"\")})")'
