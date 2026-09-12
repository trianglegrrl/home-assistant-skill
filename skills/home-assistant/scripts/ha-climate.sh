#!/usr/bin/env bash
# Usage: ha-climate.sh [entity or name]                 -> show thermostat status
#        ha-climate.sh [entity or name] --set 21        -> set target temperature (in the thermostat's unit)
#        ha-climate.sh [entity or name] --mode heat|cool|heat_cool|off
# With one climate entity in HA the name can be omitted.
source "$(dirname "$0")/lib.sh"
Q=""; SET=""; MODE=""
while [[ $# -gt 0 ]]; do case "$1" in
  --set) need_value "$@"; SET="$2"; shift 2;; --mode) need_value "$@"; MODE="$2"; shift 2;;
  *) Q="$1"; shift;; esac; done
if [[ -z "$Q" ]]; then
  N="$(ha_get states | python3 -c 'import json,sys; ids=[e["entity_id"] for e in json.load(sys.stdin) if e["entity_id"].startswith("climate.")]; print(ids[0] if len(ids)==1 else "")')"
  [[ -n "$N" ]] || die "Specify which thermostat (run ha-entities.sh --domain climate)"; Q="$N"
fi
ID="$(ha_resolve "$Q" climate)"
[[ -n "$SET" ]] && { [[ "$SET" =~ ^[0-9]+([.][0-9]+)?$ ]] || die "--set needs a number"; "$(dirname "$0")/ha-call.sh" climate.set_temperature --entity "$ID" --data "{\"temperature\":$SET}" >/dev/null; }
[[ -n "$MODE" ]] && "$(dirname "$0")/ha-call.sh" climate.set_hvac_mode --entity "$ID" --data "{\"hvac_mode\":\"$MODE\"}" >/dev/null
ha_get "states/$ID" | python3 -c '
import json, sys
e=json.load(sys.stdin); a=e["attributes"]; u=a.get("temperature_unit","") or ""
def t(k): v=a.get(k); return f"{v}{u}" if v is not None else "-"
print(f"{a.get(\"friendly_name\",e[\"entity_id\"])}: mode {e[\"state\"]}, currently {t(\"current_temperature\")}, target {t(\"temperature\")}"
      + (f" (range {t(\"target_temp_low\")}..{t(\"target_temp_high\")})" if a.get("target_temp_low") is not None else "")
      + (f", humidity {a[\"current_humidity\"]}%" if a.get("current_humidity") is not None else "")
      + (f", action: {a[\"hvac_action\"]}" if a.get("hvac_action") else "")
      + (f", preset: {a[\"preset_mode\"]}" if a.get("preset_mode") else ""))'
