# Cursor Cloud agents — roblox-dodgeball

This repo is **Luau sources + per-script Studio docs**, not a runnable game. Play testing happens in **Roblox Studio** on a developer machine.

## Where to work

| Area | Purpose |
|------|---------|
| `scripts/*.lua` | Source of truth for Studio scripts (server, local, modules under `scripts/throw/`) |
| `docs/*.md` | One markdown file per script: Explorer path, human-built objects, config knobs, auto-created instances |
| `README.md` | System map, scripts table, how to paste one file |

No **Rojo** sync: scripts are copied from GitHub into Studio.

## Editing rules

- When gameplay or Studio **human** setup changes, update the **matching** `docs/<ScriptName>.md` (and `docs/DefaultThrow.md` for throw modules). Do not add numbered step guides.
- Prefer docs in `docs/` over long comments in `.lua`. A one-line pointer at the top of a script to its doc is fine.
- Keep language plain and short — not a children’s lesson, not “step 01–06”.
- Do not change Lua behavior unless the task requires it.

## Game flow (for code changes)

- **Lobby + matches:** `LobbyService.server.lua`, `LobbyJoinNextMatchClient.local.lua`, **RoundStatus** attributes.
- **Rounds:** `RoundService.server.lua` with `DodgeballService.server.lua` and `DodgeballConfig.lua`.
- **Teams:** `TeamAutoBalance.server.lua` (lobby-aware; reads `MatchPhase`).
- **Throws:** `DodgeballThrowInput.local.lua` + `DodgeballService` + `throw/DefaultThrow.lua`.

Cross-check human setup against the script’s doc, not legacy folders.

## Cloud environment

- **Install:** `.cursor/install-tools.sh` (Selene, StyLua under `~/.local/bin`).
- **Network:** No repo egress allowlist — use account **Allow all network access** where needed.
- **No dev server** — nothing to run in cloud terminals for play mode.
- **PRs:** Lua + markdown; avoid new npm/node unless explicitly required.

## Checks before a PR

From repo root:

```bash
stylua scripts/
selene scripts/ 2>/dev/null || true
```