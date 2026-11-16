# LobbyService

**Purpose:** Drives **Lobby** ↔ **InMatch** phases: lobby countdown when enough players opt in, team assignment for joiners, teleport to arena spawns, match score to `MATCH_POINTS_TO_WIN`, then return everyone to the lobby spawn.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `LobbyService` | `ServerScriptService/LobbyService` | **Script** |

Paste from [scripts/LobbyService.server.lua](../scripts/LobbyService.server.lua).

**Depends on:** `DodgeballConfig`, **RoundService**, **DodgeballService**, **TeamAutoBalance** (team assignment after countdown).

## What you build in Studio

| Item | Details |
|------|---------|
| Lobby **SpawnLocation** | In **Workspace**. Default: rename to `LobbySpawn` (`LOBBY_SPAWN_NAME`). **TeamColor** = **Neutral**, **Neutral** on. **AllowTeamChangeOnTouch** off if you do not want team touch on that pad. |
| Tag option | Or tag a SpawnLocation with the string in `LOBBY_SPAWN_TAG` (leave tag empty in config to use name only). |
| Arena spawns | Team pads: **Neutral** off, **TeamColor** matches **Teams → Red** or **Blue** — same rules as [TeamAutoBalance.md](TeamAutoBalance.md). |
| Teams | `Red` and `Blue` with distinct **TeamColor** |

You choose where the lobby pad sits on the map; scripts only find it by name or tag.

## What scripts create (do not duplicate)

| Item | Location |
|------|----------|
| `SetJoinNextMatch` RemoteEvent | Under `ReplicatedStorage/DodgeballRemotes` (extends folder from **DodgeballService**) |
| `RoundStatus` attributes | `MatchPhase`, `MatchScore_*`, `LobbyCountdownEndsAt`, `LobbyOptedInCount`, etc. |
| Player attributes | `MatchParticipant`, `JoinNextMatch` (name from config) |

## Config knobs

| Key | Role |
|-----|------|
| `LOBBY_COUNTDOWN_SECONDS` | Wait before match when 2+ opted in |
| `MATCH_POINTS_TO_WIN` | Round wins needed to win match |
| `LOBBY_SPAWN_NAME`, `LOBBY_SPAWN_TAG` | Finding lobby pad |
| `JOIN_NEXT_MATCH_ATTR`, `SET_JOIN_NEXT_MATCH_REMOTE_NAME` | Opt-in queue |
| `TEAM_NAMES` | Match score keys and team assignment |

## Opt-in rules (summary)

- First join: counts as joining next match unless player sets opt-out.
- Countdown runs when **at least 2** players have opt-in true (`JoinNextMatch` not false).
- **Spectating** players stay on lobby pad during **InMatch**; they queue for the **next** match.

## What not to build

Do not duplicate **LobbyService**. Do not create `SetJoinNextMatch` manually. Do not use team-colored spawns for the lobby pad.