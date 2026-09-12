#!/usr/bin/env bash
# Shared helpers for the home-assistant skill. Source this; do not run it.
# Token lives in $HA_TOKEN_FILE (default ~/.config/homeassistant/token.env) and is never printed.
set -euo pipefail
HA_TOKEN_FILE="${HA_TOKEN_FILE:-$HOME/.config/homeassistant/token.env}"
[[ -r "$HA_TOKEN_FILE" ]] || { echo "ERROR: token file not readable: $HA_TOKEN_FILE (HA_URL, HA_TOKEN)" >&2; exit 1; }
# shellcheck disable=SC1090
source "$HA_TOKEN_FILE"
[[ -n "${HA_URL:-}" && -n "${HA_TOKEN:-}" ]] || { echo "ERROR: HA_URL / HA_TOKEN missing in $HA_TOKEN_FILE" >&2; exit 1; }
die() { echo "ERROR: $*" >&2; exit 1; }
need_value() { [[ $# -ge 2 && -n "${2:-}" ]] || die "Flag $1 requires a value"; }
# ha_get PATH            -> GET  $HA_URL/api/PATH
# ha_post PATH JSON      -> POST $HA_URL/api/PATH with a JSON body
# The bearer header is passed through a curl config on stdin so the token never appears in argv.
_ha_curl() {
  local method="$1" path="$2" body="${3:-}"
  printf 'header = "Authorization: Bearer %s"\n' "$HA_TOKEN" | curl -sS --config - -X "$method" -H "Content-Type: application/json" ${body:+--data "$body"} "$HA_URL/api/$path" -w '\n%{http_code}'
}
ha_call() {
  local out code
  out="$(_ha_curl "$@")"; code="${out##*$'\n'}"; out="${out%$'\n'*}"
  [[ "$code" =~ ^2 ]] || die "HA returned HTTP $code for $2: ${out:0:300}"
  printf '%s' "$out"
}
ha_get()  { ha_call GET "$1"; }
ha_post() { ha_call POST "$1" "$2"; }
# Resolve a name or substring to exactly one entity_id (optionally within a domain).
ha_resolve() {
  local query="$1" domain="${2:-}"
  ha_get states | HA_Q="$query" HA_D="$domain" python3 -c '
import json, os, sys
q=os.environ["HA_Q"].lower(); d=os.environ["HA_D"]
ents=[e for e in json.load(sys.stdin) if not d or e["entity_id"].startswith(d+".")]
exact=[e for e in ents if e["entity_id"]==q]
if exact: print(exact[0]["entity_id"]); sys.exit(0)
hits=[e for e in ents if q in e["entity_id"].lower() or q in (e["attributes"].get("friendly_name") or "").lower()]
if len(hits)==1: print(hits[0]["entity_id"]); sys.exit(0)
msg="No entity matches" if not hits else "Ambiguous entity"
opts=", ".join(f"{e[\"entity_id\"]} ({e[\"attributes\"].get(\"friendly_name\",\"\")})" for e in (hits or ents)[:25])
print(f"ERROR: {msg} {q!r}. Options: {opts}", file=sys.stderr); sys.exit(1)'
}
