# DodgeballBallTemplate

**Purpose:** One place that applies **shared ball look and physics** from **DodgeballConfig** (`BALL_*` keys) onto a `BasePart`. **DodgeballService** uses this when arena balls load; **LobbyPracticeBallService** uses it when spawning practice balls.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballBallTemplate` | `ServerScriptService/DodgeballBallTemplate` | **ModuleScript** |
| `DodgeballConfig` | `ServerScriptService/DodgeballConfig` | **ModuleScript** (required) |
| `DodgeballThrowerCollision` | `ServerScriptService/DodgeballThrowerCollision` | **ModuleScript** (required) |

Paste from [DodgeballBallTemplate.lua](./DodgeballBallTemplate.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

## What you build in Studio

Nothing beyond **DodgeballConfig** tuning. Arena ball Parts still live under `Workspace/Dodgeballs` — on server start **DodgeballService** runs `applyAppearance` so they match config even if you sized them differently in Studio.

## API (for other server scripts)

| Function | Role |
|----------|------|
| `applyAppearance(part)` | Set shape, size, color, material, physical properties from config |
| `createPart()` | New `Part` with defaults + appearance (not parented) |
| `halfHeight()` | `BALL_DIAMETER / 2` for spawn offsets |

## Config knobs

All **`BALL_*`** keys in [DodgeballConfig.md](../DodgeballConfig/DodgeballConfig.md) — not lobby spawn tags or counts.

## What not to build

Do not duplicate ball size/color in **LobbyPracticeBallService** — change **DodgeballConfig** instead.