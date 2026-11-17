# DodgeballService

**Purpose:** Server rules for dodgeballs: pickup on slow touch, hold timer, aim/throw from client aim data, OUT elimination with spherecast sweeps during throws, ball reset for rounds, and bridge hooks for **RoundService**.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballService` | `ServerScriptService/DodgeballService` | **Script** |
| `DodgeballConfig` | `ServerScriptService/DodgeballConfig` | **ModuleScript** (required) |
| `DodgeballBallTemplate` | `ServerScriptService/DodgeballBallTemplate` | **ModuleScript** (required) |
| `DodgeballThrowerCollision` | `ServerScriptService/DodgeballThrowerCollision` | **ModuleScript** (required) |
| `throw` | `ServerScriptService/throw` | **Folder** |
| `DefaultThrow` | `ServerScriptService/throw/DefaultThrow` | **ModuleScript** (required) |

Paste from [DodgeballService.server.lua](./DodgeballService.server.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

## What you build in Studio

| Item | Details |
|------|---------|
| `Dodgeballs` folder | Under **Workspace**, name must match `BALL_FOLDER_NAME` in config (default `Dodgeballs`). |
| Ball Parts | Inside the folder: **Ball** parts, **Anchored** off, **CanCollide** on, **CanTouch** on. Any Part name is fine. On load, **DodgeballBallTemplate** applies `BALL_*` from config so they match lobby practice balls. |
| Tag (recommended) | Add tag `Dodgeball` (or value of `DODGEBALL_TAG`) in Tag Editor. |
| Teams / spawns | Same as [TeamAutoBalance.md](../TeamAutoBalance/TeamAutoBalance.md) — friendly fire does not eliminate. |

On first run the service can create an **empty** `Dodgeballs` folder and warn in **Output** — add ball Parts for gameplay.

## What scripts create (do not duplicate)

| Item | Location | Contents |
|------|----------|----------|
| `DodgeballRemotes` | `ReplicatedStorage` | `RequestThrow`, `StartAiming` RemoteEvents; folder attributes mirror aim/hold tunables, ball tags, `HIT_MIN_SPEED`, and ball visual effect defaults from config (for **DodgeballBallVisualEffectsClient**) |
| `DodgeballRoundBridge` | `ServerScriptService` | BindableFunction/Event for **RoundService** (reset balls, drop held, etc.) |
| Empty `Dodgeballs` | `Workspace` | Only if missing — prefer you add balls yourself |

**LobbyService** adds `SetJoinNextMatch` under the same remotes folder — do not create remotes by hand.

**LobbyPracticeBallService** also listens on `RequestThrow` / `StartAiming` for players holding lobby practice balls (see [LobbyPracticeBallService.md](../LobbyPracticeBallService/LobbyPracticeBallService.md)). Arena ball logic in this script is unchanged.

## Config knobs (most used)

| Key | Role |
|-----|------|
| `PICKUP_MAX_SPEED`, `PICKUP_COOLDOWN_SECONDS` | Pickup rules |
| `HIT_MIN_SPEED`, `THROW_OUT_WINDOW_SECONDS`, `DEBUG_ELIMINATION` | OUT detection |
| `THROW_IMPULSE`, `ACTIVE_THROW_PROFILE` | Throw strength and module |
| `BALL_MAX_HOLD_SECONDS`, `HOLD_*`, `AIM_*` | Hold and aim server enforcement |
| `THROWER_BALL_NOCOLLIDE_SECONDS` | Thrower–ball no-collide grace on release ([DodgeballThrowerCollision.md](../DodgeballThrowerCollision/DodgeballThrowerCollision.md)) |
| `BALL_FOLDER_NAME`, `DODGEBALL_TAG` | Finding balls |
| `DEFAULT_WALK_SPEED`, `DEFAULT_JUMP_POWER`, `OUT_STRAY_RESPAWN_FALLBACK` | OUT / movement |

## Client pairing

**DodgeballThrowInput** sends throw aim/power and reads remotes. Exactly **one** LocalScript under **StarterPlayerScripts**.

## What not to build

- Do not add RemoteEvents under `DodgeballRemotes` manually.
- Do not paste into `DodgeballRoundBridge`.
- Do not rely on `.Touched` alone for OUT — this service uses Heartbeat spherecasts during the throw window.