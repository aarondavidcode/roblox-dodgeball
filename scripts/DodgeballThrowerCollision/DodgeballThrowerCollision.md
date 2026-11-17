# DodgeballThrowerCollision

**Purpose:** After a throw or hold roll releases a ball, the **thrower only** temporarily does not physically collide with that ball (and other dodgeballs in `DodgeballBall`). Other players keep normal ball collision. Groups revert automatically after `THROWER_BALL_NOCOLLIDE_SECONDS` in **DodgeballConfig**.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballThrowerCollision` | `ServerScriptService/DodgeballThrowerCollision` | **ModuleScript** |

Paste from [DodgeballThrowerCollision.lua](./DodgeballThrowerCollision.lua).

## What you build in Studio

**Nothing extra.** On first `require`, the module registers **CollisionGroup** names `DodgeballBall` and `DodgeballThrower` and sets them non-collidable with each other. Balls get `DodgeballBall` from **DodgeballBallTemplate**; thrower parts switch to `DodgeballThrower` only for the grace window.

## API (server)

| Function | Role |
|----------|------|
| `assignBallCollisionGroup(part)` | Tag a ball Part with `DodgeballBall` |
| `beginThrowerGrace(player, ball?)` | Start no-collide for this thrower; optional ball gets the ball group at release |

**DodgeballService** and **LobbyPracticeBallService** call `beginThrowerGrace` from `releaseBallForThrow` so throws and max-hold rolls share the same behavior.

## Config

| Key | Meaning |
|-----|---------|
| `THROWER_BALL_NOCOLLIDE_SECONDS` | Grace time after release (default `0.35`; set `0` to disable) |

See [DodgeballConfig.md](../DodgeballConfig/DodgeballConfig.md).

## Related scripts

Required by **DodgeballBallTemplate**, **DodgeballService**, **LobbyPracticeBallService**.