# DodgeballConfig

**Purpose:** One shared table of numbers and names for dodgeball, rounds, and lobby flow. Every server script and the throw module `require` this ModuleScript. Change tuning here instead of editing multiple scripts.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballConfig` | `ServerScriptService/DodgeballConfig` | **ModuleScript** |

Paste from [DodgeballConfig.lua](./DodgeballConfig.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

## What you build in Studio

| Item | You set it? | Notes |
|------|-------------|-------|
| Team names `Red` / `Blue` | **Yes** | Must match `TEAM_NAMES` in this file and **Teams** in Explorer |
| Lobby spawn name or tag | **Yes** | `LOBBY_SPAWN_NAME` (default `LobbySpawn`) or `LOBBY_SPAWN_TAG` |
| Ball folder | **Yes** | `BALL_FOLDER_NAME` (default `Dodgeballs`) under **Workspace** |
| Optional ball tag | **Yes** | `DODGEBALL_TAG` (default `Dodgeball`) via Tag Editor |
| Lobby practice spawn volumes | **Yes** | Tag `LobbyBallSpawnVolume`; optional `LobbyBallExcludeZone` — see [LobbyPracticeBallService.md](../LobbyPracticeBallService/LobbyPracticeBallService.md) |
| Player attribute `JoinNextMatch` | **No** | Name in config; **LobbyService** / clients set values at run time |

## What scripts create (do not duplicate)

| Name | Location | Created by |
|------|----------|------------|
| `DodgeballRemotes` | `ReplicatedStorage` | **DodgeballService** (+ **LobbyService** adds `SetJoinNextMatch`) |
| `RoundStatus` | `ReplicatedStorage` | **RoundService** / **LobbyService** |
| `DodgeballRoundBridge` | `ServerScriptService` | **DodgeballService** |

## Config knobs (human-facing)

| Key | Meaning |
|-----|---------|
| `PICKUP_MAX_SPEED`, `HIT_MIN_SPEED`, `THROW_OUT_WINDOW_SECONDS` | Pickup vs elimination speed rules |
| `THROW_IMPULSE` | Max throw strength at 100% power |
| `AIM_POWER_CHARGE_SECONDS`, `AIM_MAX_SECONDS`, `BALL_MAX_HOLD_SECONDS` | Aim UI timing (mirrored on remotes as attributes for clients) |
| `HOLD_PENALTY_*`, `HOLD_ROLL_IMPULSE` | Penalty when you hold a ball too long without aiming |
| `BALL_FOLDER_NAME`, `DODGEBALL_TAG` | Where balls live and optional tag |
| `ACTIVE_THROW_PROFILE` | Module name under `ServerScriptService/throw/` (default `Default`) |
| `REMOTES_FOLDER_NAME`, `THROW_REMOTE_NAME` | Remote folder and throw event names |
| `ROUND_INTERMISSION_SECONDS`, `TEAM_NAMES`, `ROUND_TIE_RESET_DELAY_SECONDS` | Round pacing |
| `ROUND_STATUS_FOLDER_NAME` | Folder name for match/round UI data |
| `DEFAULT_WALK_SPEED`, `DEFAULT_JUMP_POWER`, `OUT_STRAY_RESPAWN_FALLBACK` | OUT / respawn behavior |
| `LOBBY_COUNTDOWN_SECONDS`, `MATCH_POINTS_TO_WIN` | Lobby timer and match length |
| `LOBBY_SPAWN_NAME`, `LOBBY_SPAWN_TAG` | How **LobbyService** finds the lobby pad |
| `JOIN_NEXT_MATCH_ATTR`, `SET_JOIN_NEXT_MATCH_REMOTE_NAME` | Opt-in queue |
| `DEBUG_ELIMINATION` | Extra **Output** when hits do not eliminate |
| `LOBBY_BALL_*` | Lobby practice spawn folder, CollectionService tags, min/max per area, idle timeout, maintenance interval, ball size — see [LobbyPracticeBallService.md](../LobbyPracticeBallService/LobbyPracticeBallService.md) |

## Related scripts

Requires nothing at load time. Required by **TeamAutoBalance**, **DodgeballService**, **LobbyPracticeBallService**, **RoundService**, **LobbyService**, **DefaultThrow**, and indirectly by client scripts (names must stay in sync).