# Cursor Cloud agents — roblox-dodgeball

This repo is **guides + copy-paste Luau**, not a runnable game. Roblox Studio on a family PC is where the place is built and tested.

## Where to work

| Area | Purpose |
|------|---------|
| `scripts/*.lua` | Source of truth for Studio scripts (server, local, modules under `scripts/throw/`) |
| `01-build-your-map` … `06-lobby-and-matches` | Kid-friendly step guides — keep the same clear, encouraging tone as existing READMEs |
| `scripts/README.md` | Maps repo files → Studio object names and locations |

No **Rojo** sync in this repo: kids paste from GitHub into Studio.

## Game flow (for code changes)

- **Lobby + matches:** `LobbyService.server.lua` drives lobby countdown, match state, and first-to-3 round wins; `LobbyJoinNextMatchClient.local.lua` is the **Join next match** / spectate UI.
- **Rounds:** `RoundService.server.lua` with `DodgeballService.server.lua` and shared `DodgeballConfig.lua`.
- **Teams:** `TeamAutoBalance.server.lua` (lobby-aware in step 6).

When editing guides, say what to paste and where in Studio — match `scripts/README.md`.

## Cloud environment

- **Install:** `.cursor/install-tools.sh` (Selene linter, StyLua formatter under `~/.local/bin`).
- **Network:** No `egressAllowlist` in `.cursor/environment.json`—rely on account **Allow all network access** (Cloud Agents → Security).
- **No dev server** — nothing to keep running in `terminals`; Play testing is in Studio (F5).
- **PRs:** Lua + markdown only; do not add npm/node unless the project explicitly needs it.

## Suggested checks before opening a PR

From repo root (PATH should include `~/.local/bin` after install):

```bash
stylua scripts/
selene scripts/ 2>/dev/null || true
```

Selene may need a project `selene.toml` later; formatting with StyLua is the main automated check today.