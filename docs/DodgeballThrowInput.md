# DodgeballThrowInput

**Purpose:** On each player’s device: hold-to-aim (F, left click, or gamepad R2), power charge, hold-time bar after pickup, and crosshair UI. Sends aim direction and power to the server via remotes.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballThrowInput` | `StarterPlayer/StarterPlayerScripts/DodgeballThrowInput` | **LocalScript** |

Paste from [scripts/DodgeballThrowInput.local.lua](../scripts/DodgeballThrowInput.local.lua).

## What you build in Studio

| Item | Details |
|------|---------|
| Script placement | **Only** under **StarterPlayer → StarterPlayerScripts**. Not **StarterGui**. |
| Duplicates | Remove any older throw LocalScripts elsewhere. |

## What scripts create at run time (do not duplicate)

| UI | Under | Built by |
|----|--------|----------|
| `DodgeballAimGui` | `Players/<you>/PlayerGui` | This LocalScript |
| `Crosshair`, `HoldBarBackground`, `PowerBarBackground` | Inside `DodgeballAimGui` | This LocalScript |

## Server / data it expects

| Item | Source |
|------|--------|
| `ReplicatedStorage/DodgeballRemotes` | **DodgeballService** (`RequestThrow`, `StartAiming`) |
| Attributes on remotes folder | Aim/hold seconds from **DodgeballConfig** |
| `ReplicatedStorage/RoundStatus` → `MatchPhase` | **LobbyService** |
| Player `IsOut`, `MatchParticipant` | Server scripts |

Throw and aim for **arena** balls are blocked in **Lobby**, when **OUT**, or when `MatchParticipant` is false during **InMatch**.

**Lobby practice balls** (from **LobbyPracticeBallService**): neutral spectators and lobby waiters can aim/throw while holding a ball tagged / attributed as lobby practice — same controls as match throws.

## Config knobs

Reads tunables from remote folder attributes (from **DodgeballConfig**): `AIM_POWER_CHARGE_SECONDS`, `AIM_MAX_SECONDS`, `BALL_MAX_HOLD_SECONDS`.

## Testing

**F5** → **Output**: search `[DodgeballThrowInput]`. Remotes missing → **DodgeballService** not running or stale copy. During **InMatch**, pick up a ball → yellow hold bar; hold throw → crosshair + blue power bar.

## What not to build

Do not hand-build `DodgeballAimGui` in **StarterGui** — this script recreates it. Do not create `RequestThrow` / `StartAiming` yourself.