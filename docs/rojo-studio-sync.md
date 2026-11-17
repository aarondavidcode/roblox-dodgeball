# Rojo sync for local Studio development

Use [Rojo](https://rojo.space/) to sync Luau from this repo into an **existing** dodgeball place. Rojo does **not** replace your arena, teams, spawns, or UI chrome — only scripts under the paths in [`default.project.json`](../default.project.json).

## What gets synced

| Disk pattern | Roblox instance |
|--------------|-----------------|
| `*.server.lua` | `Script` |
| `*.client.lua` | `LocalScript` |
| Plain `*.lua` / `*.luau` (module paths) | `ModuleScript` |
| `scripts/ball-physics/src/` | `ReplicatedStorage/BallPhysics` (ModuleScript tree) |
| `scripts/throw/DefaultThrow/` | `ServerScriptService/throw/DefaultThrow` |
| `scripts/ballVisualEffects/*/` | `StarterPlayerScripts/ballVisualEffects/*` |

Explorer **names** match the paste table in [README.md](../README.md). `require()` paths are unchanged.

## Place file (keep local)

**Do not commit** your full game place. Keep `YourDodgeballPlace.rbxlx` (or an unpublished Studio place) on your machine:

- Build once in Studio: Workspace arena, `Teams` (Red/Blue), spawns, `Workspace/Dodgeballs`, optional `StarterGui/RoundStatus/CountdownLabel`, lobby volumes, etc. (see each script’s colocated `.md`).
- Open that place when you **Connect** in the Rojo plugin — scripts merge in; world objects stay as you built them.
- Rojo’s `default.project.json` includes a minimal `StarterGui/RoundStatus` **ScreenGui** with only `RoundStatusClient`. If you already have `RoundStatus`, sync updates the script and leaves your labels alone (`$ignoreUnknownInstances`).

To smoke-test scripts without your place: `rojo build default.project.json -o build/dev.rbxlx` (gitignored). That file is scripts only, not a playable arena.

## Aaron setup (recommended)

1. **Install tooling**
   - [Rokit](https://github.com/rojo-rbx/rokit): `rokit install` at repo root (reads [`rokit.toml`](../rokit.toml) — pinned Rojo + StyLua).
   - Or install matching versions from each tool’s releases and add them to `PATH`.
2. **Clone and open** this repo in Cursor.
3. **Install the Rojo plugin** in Roblox Studio (from the [Rojo releases](https://github.com/rojo-rbx/rojo/releases) page or Studio plugin search).
4. In a terminal at the repo root: `rojo serve` (default port 34872).
5. Open your **local** dodgeball place in Studio → **Rojo** plugin → **Connect** to `localhost:34872`.
6. Edit Luau under `scripts/` in Cursor; save → Studio updates the matching instances.

**Formatter (optional):** `stylua scripts/`

## Paste workflow still works

Copy/paste from GitHub is unchanged. Rojo is additive: same source files, no duplicate Explorer names required.

## Cloud agents

`bash .cursor/install-tools.sh` installs StyLua, Selene, and Rojo. Verify with:

```bash
rojo build default.project.json -o /tmp/rojo-test.rbxlx
rojo sourcemap default.project.json
```

## Troubleshooting

| Issue | Fix |
|-------|-----|
| `require` fails after sync | Instance **name** in Explorer must match README; reconnect Rojo after renaming. |
| Duplicate `RoundStatus` | Use one ScreenGui; delete an empty duplicate Rojo created before you had labels. |
| `BallPhysics` errors | Root must be a **ModuleScript** named `BallPhysics`, not a Folder — see [ball-physics/README.md](../scripts/ball-physics/README.md). |
| Plugin won’t connect | Check firewall; try `rojo serve --port 34872` and match port in the plugin. |