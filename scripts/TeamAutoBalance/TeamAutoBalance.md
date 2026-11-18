# TeamAutoBalance

**Purpose:** Keeps **Red** and **Blue** balanced when players join during a match. In **lobby**, players stay **Neutral** with no team until **LobbyService** starts a match. Spectators and mid-match joiners stay Neutral at the lobby pad.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `TeamAutoBalance` | `ServerScriptService/TeamAutoBalance` | **Script** (not LocalScript) |

Paste from [TeamAutoBalance.server.lua](./TeamAutoBalance.server.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

**Depends on:** `DodgeballConfig` ModuleScript in the same parent. Works with **LobbyService** / **RoundStatus** `MatchPhase`.

**Single-player testing:** When test NPCs are active ([DodgeballMatchNpc](../DodgeballMatchNpc/DodgeballMatchNpc.md)), they are balanced onto Red/Blue in the same pass as human players (sort key `NpcSortId`).

## What you build in Studio

| Item | Details |
|------|---------|
| **Teams** | Under **Teams**, create **Team** objects named exactly `Red` and `Blue` (must match `TEAM_NAMES` in **DodgeballConfig**). |
| Team colors | Each team needs a unique **TeamColor** (e.g. Really red / Really blue). |
| **AutoAssignable** | Leave **unchecked** on both teams — this script assigns teams. |
| Team spawns | In **Workspace**, **SpawnLocation**(s) per side: **Neutral** = off, **TeamColor** must **match** the team’s **TeamColor** (not just visual **Color**). Names like `RedSpawn` / `BlueSpawn` are fine — matching is by **TeamColor**, not name. **Duration** is forced to `0` at run time so players are not spawn-immune. |
| Default center spawn | Remove or fix the baseplate **SpawnLocation** if it has **Neutral** on and steals spawns. |

**Lobby pad:** **Neutral** on, lobby **TeamColor** — see [LobbyService.md](../LobbyService/LobbyService.md). Team pads must **not** use the lobby spawn name/tag from config.

## What scripts create (do not duplicate)

| Item | Notes |
|------|-------|
| `MatchParticipant` on players | Set by **LobbyService**; this script reads it. |
| `JoinNextMatch` on players | Config name; default opt-in unless player sets false. |

## Config knobs

| Key | Role |
|-----|------|
| `TEAM_NAMES` | Must match Explorer **Teams** names |
| `JOIN_NEXT_MATCH_ATTR` | Attribute name for queue opt-in |
| `ROUND_STATUS_FOLDER_NAME` | Reads `MatchPhase` from **ReplicatedStorage** |

## Behavior summary

- **Lobby:** `Neutral = true`, `Team = nil`.
- **InMatch** for joiners who are match participants: assign smaller team (tie → Red first).
- Sets **Neutral** off before **Team** (Roblox recommendation). May call **LoadCharacter** once if spawn was wrong when `CharacterAutoLoads` is true.
- **DodgeballService** sets global `Players.CharacterAutoLoads = false`; respawns are explicit from **LobbyService** / **RoundService**.

## What not to build

Do not add a second copy of this Script. Do not use LocalScript for team logic.