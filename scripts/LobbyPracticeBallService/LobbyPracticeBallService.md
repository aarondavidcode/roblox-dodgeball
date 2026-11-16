# LobbyPracticeBallService

**Purpose:** Spawns **lobby practice balls** in tagged volumes so neutral players (lobby waiters and mid-match spectators) can pick up and throw while they wait. Throw math uses **DefaultThrow** and the same **RequestThrow** / **StartAiming** remotes as **DodgeballService**. Lobby hits never eliminate anyone or deal match damage.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `LobbyPracticeBallService` | `ServerScriptService/LobbyPracticeBallService` | **Script** |
| `DodgeballConfig` | `ServerScriptService/DodgeballConfig` | **ModuleScript** (required) |
| `DodgeballBallTemplate` | `ServerScriptService/DodgeballBallTemplate` | **ModuleScript** (required) |
| `DefaultThrow` | `ServerScriptService/throw/DefaultThrow` | **ModuleScript** (required) |

Paste from [LobbyPracticeBallService.server.lua](./LobbyPracticeBallService.server.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

**Depends on:** **DodgeballService** (creates remotes), **LobbyService** (`MatchPhase` on `RoundStatus`), **DodgeballThrowInput** (client gates for lobby practice).

## What you build in Studio

| Item | Details |
|------|---------|
| Spawn volumes | One or more **Parts** or **Models** in the lobby. Tag each with **`LobbyBallSpawnVolume`** (or the value of `LOBBY_BALL_SPAWN_VOLUME_TAG` in config). Size them where balls should appear — the script picks random points inside each part’s box. |
| Per-area counts (optional) | On a volume: attributes **`LobbyBallMin`** and **`LobbyBallMax`** (numbers). If missing, config defaults `LOBBY_BALL_MIN_PER_AREA` / `LOBBY_BALL_MAX_PER_AREA` apply. |
| Exclude zones (optional) | Tag arena or match-side **Parts** with **`LobbyBallExcludeZone`** (`LOBBY_BALL_EXCLUDE_ZONE_TAG`). Any lobby ball that enters is deleted and respawns in its spawn area. |
| Lobby pad | Same lobby **SpawnLocation** as **LobbyService** — keep practice volumes near the pad, not inside team arenas. |

You do **not** place lobby ball Parts by hand. The script creates them under `Workspace/LobbyPracticeBalls` (`LOBBY_BALL_FOLDER_NAME`).

## CollectionService tags (summary)

| Tag (default name) | On | Role |
|--------------------|-----|------|
| `LobbyBallSpawnVolume` | Lobby region Part(s) | Spawn bounds; multiple areas supported |
| `LobbyBallExcludeZone` | Arena / off-limits Part(s) | Ball touching inside → instant recover + respawn |
| `LobbyPracticeBall` | *(script adds to balls)* | CollectionService tag; arena dodgeballs use `DODGEBALL_TAG` instead |

## What scripts create (do not duplicate)

| Item | Location |
|------|----------|
| `LobbyPracticeBalls` folder | `Workspace` |
| Ball Parts | Inside that folder, tagged `LobbyPracticeBall` |

Do not create **RequestThrow** yourself — **DodgeballService** owns `ReplicatedStorage/DodgeballRemotes`.

## Who can pick up / throw

Same idea as **LobbyService** opt-in spectators:

- **Neutral**, no **Team**, not **`MatchParticipant`**, not **OUT**
- **Lobby** or **InMatch** (spectators on the lobby pad during a match)

Match players in the arena use arena balls only; this script drops lobby balls if someone becomes a participant.

## Safety behavior

- No OUT, no damage, no elimination sweeps on lobby balls.
- Hit on a **`MatchParticipant`** → ball recovers immediately and respawns in its area.
- Ball leaves all spawn volumes or enters an exclude zone → recover + respawn.
- Thrown balls use a light server sweep only to detect match participants (not eliminations).

## Config knobs

**Shared ball look/throw:** `BALL_*` plus pickup/throw keys in [DodgeballConfig.md](../DodgeballConfig/DodgeballConfig.md) — applied via [DodgeballBallTemplate.md](../DodgeballBallTemplate/DodgeballBallTemplate.md) (same as arena balls).

**Lobby-only:** `LOBBY_BALL_*` spawn folder, volume/exclude tags, min/max per area, idle timeout, maintenance interval, `LOBBY_PRACTICE_BALL_ATTR`.

**Idle timeout:** when a ball is not held and stays slower than pickup speed for `LOBBY_BALL_IDLE_TIMEOUT_SECONDS`, it respawns.

**Maintenance:** `LOBBY_BALL_MAINTENANCE_INTERVAL_SECONDS` (default 8s) rechecks counts, idle, and bounds. Keep this at **5–10 seconds** or slower — not every frame.

## Related docs

- [DodgeballThrowInput.md](../DodgeballThrowInput/DodgeballThrowInput.md) — aim UI when holding lobby balls
- [DefaultThrow.md](../DefaultThrow/DefaultThrow.md) — impulse math
- [LobbyService.md](../LobbyService/LobbyService.md) — lobby vs spectator rules

## What not to build

- Do not put lobby practice balls in `Workspace/Dodgeballs` or tag them `Dodgeball`.
- Do not add a second throw RemoteEvent for practice.