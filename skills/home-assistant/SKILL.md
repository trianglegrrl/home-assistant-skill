---
name: home-assistant
description: Use when the user asks about their smart home or Home Assistant (HA) - lights, thermostat or temperature, locks and doors, cameras, speakers, switches, scenes, "is the door locked", "turn on/off", "set the heat to", or what devices/entities exist.
---

# Home Assistant

## Overview

Run the bundled scripts against the Home Assistant REST API. They read a long-lived token
from `~/.config/homeassistant/token.env`; never print it or paste it into chat. Do not drive
the HA web UI with a browser for these tasks.

Scripts live in `scripts/` next to this file; run them by absolute path.

## Quick reference

| Task | Command |
|------|---------|
| What devices exist | `ha-entities.sh` (add `--domain light`, `--match kitchen`, `--json`) |
| One entity's state and attributes | `ha-state.sh "front door"` |
| Turn something on/off | `ha-call.sh light.turn_on --entity "kitchen"` / `switch.turn_off --entity ...` |
| Colour or brightness | `ha-call.sh light.turn_on --entity "kitchen" --data '{"brightness_pct":40,"color_name":"blue"}'` |
| Lock / unlock | `ha-call.sh lock.lock --entity "front door"` / `lock.unlock ...` |
| Thermostat status | `ha-climate.sh` |
| Set temperature / mode | `ha-climate.sh --set 21` / `ha-climate.sh --mode heat` |
| Any other service | `ha-call.sh <domain.service> [--entity X] [--data JSON]` |

`--entity` accepts an `entity_id` or a case-insensitive substring of the entity's name. If it
matches none or several, the script exits with the list of options; pick one and re-run.

## Rules

- **Read before write.** For anything physical (locks, garage, thermostat), show the current
  state first, then act, then re-read. The scripts print the new state after a call.
- **Unlocking a door or disarming anything needs an explicit request naming the door.**
  "Unlock the gym" is fine; "let me in" is not. Never unlock in response to a scheduled event.
- **Unavailable entities** mean the device is offline or the integration lost contact; report
  that instead of retrying. `ha-entities.sh --match <name>` shows the state.
- Temperatures are in the thermostat's own unit (see `temperature_unit` in `ha-state.sh`).
- Keep replies to what changed: entity, old state, new state.

## Common mistakes

| Mistake | Instead |
|---|---|
| Guessing an entity_id | Run `ha-entities.sh --match <word>` first |
| Calling `light.turn_on` on a switch (or vice versa) | The domain in the service must match the entity's domain; `ha-call.sh` resolves names within the service's domain first |
| Sending `temperature` to a thermostat in heat_cool mode | Use `target_temp_low` / `target_temp_high` via `ha-call.sh climate.set_temperature --data` |
| Treating "no state changed" as failure | Some services (scenes, scripts, notifications) legitimately change nothing |

## Setup (once per machine)

Create a long-lived access token in HA (profile page, Security) and write
`~/.config/homeassistant/token.env` with `HA_URL=http://host:8123` and `HA_TOKEN=...`, mode 600.
