# home-assistant-skill

A Claude Code skill for [Home Assistant](https://www.home-assistant.io). Small bash scripts over
the HA REST API: list entities, read state, call services, and a thermostat helper. Names resolve
to entity ids by substring, so "turn on the kitchen lights" works without knowing the id.

## Install

```
/plugin marketplace add trianglegrrl/clave-skills
/plugin install home-assistant@clave
```

or copy `skills/home-assistant` into `~/.claude/skills/`. Needs `curl`, `jq`-free (python3 only).

Then create a long-lived access token in HA (your profile, Security tab) and save it:

```
mkdir -p ~/.config/homeassistant && chmod 700 ~/.config/homeassistant
printf 'HA_URL=http://homeassistant.local:8123\nHA_TOKEN=<token>\n' > ~/.config/homeassistant/token.env
chmod 600 ~/.config/homeassistant/token.env
```

## Scripts

| Script | Does |
|---|---|
| `ha-entities.sh` | list entities, filter by `--domain` / `--match` |
| `ha-state.sh NAME` | one entity with attributes |
| `ha-call.sh domain.service --entity NAME --data JSON` | any service call, prints what changed |
| `ha-climate.sh [--set N] [--mode M]` | thermostat status / control |

The token is passed to curl through a config on stdin, so it never appears in a process list.

MIT.
