# RoundService

**Purpose:** During an **InMatch** phase, detects when one team is entirely **OUT**, runs intermission countdown, resets balls and players, and increments round number. Awards **match points** to the round winner (full match flow with **LobbyService**).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `RoundService` | `ServerScriptService/RoundService` | **Script** |

Paste from [RoundService.server.lua](./RoundService.server.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

**Depends on:** `DodgeballConfig`, **DodgeballService** (bridge), **LobbyService** (`MatchPhase` on `RoundStatus`). Run with **TeamAutoBalance** and **DodgeballService**.

## What you build in Studio

| Item | Details |
|------|---------|
| Teams | `Red` and `Blue` per [TeamAutoBalance.md](../TeamAutoBalance/TeamAutoBalance.md) |
| Team spawns | **SpawnLocation** pads with **Neutral** off and **TeamColor** matching each team — used on reset |

No extra objects for round logic.

## What scripts create (do not duplicate)

| Item | Location | Role |
|------|----------|------|
| `RoundStatus` folder | `ReplicatedStorage` | Attributes: `RoundState`, `RoundNumber`, `IntermissionEndsAt` (and match fields from **LobbyService**) |
| Uses `DodgeballRoundBridge` | `ServerScriptService` | Created by **DodgeballService** — ball reset APIs |

## Config knobs

| Key | Role |
|-----|------|
| `TEAM_NAMES` | Which teams can win a round |
| `ROUND_INTERMISSION_SECONDS` | Pause between rounds (`0` = skip) |
| `ROUND_TIE_RESET_DELAY_SECONDS` | Everyone OUT at once |
| `ROUND_STATUS_FOLDER_NAME` | Shared status folder |
| `DEFAULT_WALK_SPEED`, `DEFAULT_JUMP_POWER` | Restore on reset |

## Behavior notes

- Until `MatchPhase` is **InMatch**, rounds do not cycle — **Output** may say waiting for lobby match start. OUT rules from **DodgeballService** can still work in sandbox tests without lobby.
- Round win → **LobbyService** adds match point; at `MATCH_POINTS_TO_WIN`, match ends and lobby resumes.

## What not to build

Do not add BindableFunctions to `DodgeballRoundBridge`. Do not create `RoundStatus` manually — let server scripts create and update it.