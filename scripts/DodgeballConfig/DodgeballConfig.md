# DodgeballConfig

**Purpose:** One shared table of numbers and names for dodgeball, rounds, and lobby flow. Every server script and the throw module `require` this ModuleScript. Change tuning here instead of editing multiple scripts.

**Repo defaults:** lighter foam-style flight — e.g. `PICKUP_MAX_SPEED` 15, `THROW_IMPULSE` 150, `AIM_POWER_CHARGE_SECONDS` 1, `BALL_MAX_HOLD_SECONDS` 10, `BALL_PHYSICAL_DENSITY` 0.3, stronger Magnus / anti-gravity and higher throw spin. Debug flags default **off** (`DEBUG_BALL_PHYSICS`, `BALL_PHYSICS_DEBUG_ENABLED`). For local Studio diagnostics, set `DEBUG_BALL_PHYSICS = true` here, or `DodgeballRemotes` attribute `DEBUG_BALL_PHYSICS = true` at runtime — see [DodgeballBallPhysicsDebug.md](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md).

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
| `HIT_FORCE_SERVER_PHYSICS_DURING_THROW` | Server sim + physics contact for OUT during live throws |
| `THROW_IMPULSE` | Max throw strength at 100% power |
| `AIM_POWER_CHARGE_SECONDS`, `AIM_MAX_SECONDS`, `BALL_MAX_HOLD_SECONDS` | Aim UI timing (mirrored on remotes as attributes for clients) |
| `HOLD_PENALTY_*`, `HOLD_ROLL_IMPULSE` | Penalty when you hold a ball too long without aiming |
| `VOLUNTARY_DROP_IMPULSE`, `VOLUNTARY_DROP_SAME_BALL_COOLDOWN_SECONDS` | Drop key: light nudge and re-pickup block on that ball |
| `THROWER_BALL_NOCOLLIDE_SECONDS` | Grace after throw/hold roll where thrower does not collide with balls (`0` = off); see [DodgeballThrowerCollision.md](../DodgeballThrowerCollision/DodgeballThrowerCollision.md) |
| `BALL_FOLDER_NAME`, `DODGEBALL_TAG` | Where balls live and optional tag |
| `BALL_DIAMETER`, `BALL_COLOR`, `BALL_MATERIAL`, `BALL_PART_NAME`, `BALL_PHYSICAL_*` | Shared look/physics for arena + lobby practice ([DodgeballBallTemplate.md](../DodgeballBallTemplate/DodgeballBallTemplate.md)) |
| `BALL_PHYSICS_TAG`, `BALL_PHYSICS_*` | Vendored [BallPhysics](../ball-physics/README.md) — magnus, knuckle, damping, anti-gravity; applied by **BallPhysicsAutoSetup** |
| `THROW_SIDE_SPIN_RAD_PER_SEC` | Initial spin on aimed throws (pairs with Magnus) — see [DefaultThrow.md](../throw/DefaultThrow/DefaultThrow.md) |
| `PICKUP_MAX_SPEED`, `THROW_IMPULSE`, `CARRY_OFFSET`, `PICKUP_COOLDOWN_SECONDS`, aim/hold keys | Shared pickup, throw, and carry feel (arena + lobby) |
| `ACTIVE_THROW_PROFILE` | Module name under `ServerScriptService/throw/` (default `Default`) |
| `REMOTES_FOLDER_NAME`, `THROW_REMOTE_NAME`, `DROP_REMOTE_NAME` | Remote folder, throw, and voluntary drop event names |
| `ROUND_INTERMISSION_SECONDS`, `TEAM_NAMES`, `ROUND_TIE_RESET_DELAY_SECONDS` | Round pacing |
| `ROUND_STATUS_FOLDER_NAME` | Folder name for match/round UI data |
| `DEFAULT_WALK_SPEED`, `DEFAULT_JUMP_POWER`, `OUT_STRAY_RESPAWN_FALLBACK` | OUT / respawn behavior |
| `LOBBY_COUNTDOWN_SECONDS`, `MATCH_POINTS_TO_WIN` | Lobby timer and match length |
| `LOBBY_SPAWN_NAME`, `LOBBY_SPAWN_TAG` | How **LobbyService** finds the lobby pad |
| `JOIN_NEXT_MATCH_ATTR`, `SET_JOIN_NEXT_MATCH_REMOTE_NAME` | Opt-in queue |
| `DEBUG_ELIMINATION` | Extra **Output** when hits do not eliminate |
| `DEBUG_BALL_PHYSICS` | `[DodgeballBallPhysicsDebug]` Output — see [DodgeballBallPhysicsDebug.md](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md) (or set `DodgeballRemotes` attribute `DEBUG_BALL_PHYSICS` at runtime) |
| `LOBBY_BALL_*` (not `BALL_*`) | Lobby-only: spawn folder, volume/exclude tags, min/max per area, idle timeout, maintenance interval, `LOBBY_PRACTICE_BALL_ATTR` — see [LobbyPracticeBallService.md](../LobbyPracticeBallService/LobbyPracticeBallService.md) |

## Related scripts

Requires nothing at load time. Required by **TeamAutoBalance**, **DodgeballBallTemplate**, **DodgeballThrowerCollision**, **DodgeballService**, **LobbyPracticeBallService**, **RoundService**, **LobbyService**, **DefaultThrow**, **BallPhysicsAutoSetup**, and indirectly by client scripts (names must stay in sync).
