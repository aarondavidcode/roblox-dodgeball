# BallPhysicsAutoSetup

**Purpose:** Server-side tracker for [ball-physics](../ball-physics/README.md). Creates a `BallPhysics.new(ball)` handler for every dodgeball Part tagged with **`BALL_PHYSICS_TAG`** (default `PhysicsBall`).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `BallPhysics` | `ReplicatedStorage/BallPhysics` | Module tree — see [ball-physics README](../ball-physics/README.md) |
| `BallPhysicsAutoSetup` | `ServerScriptService/BallPhysicsAutoSetup` | **Script** |
| `DodgeballConfig` | `ServerScriptService/DodgeballConfig` | **ModuleScript** (tuning + tag name) |

Paste from [BallPhysicsAutoSetup.server.lua](./BallPhysicsAutoSetup.server.lua).

**Load order:** Paste **`DodgeballConfig`** and the **`BallPhysics`** modules first, then this Script. It runs once at startup and applies `BALL_PHYSICS_*` keys onto the library `Config` before tracking any balls.

## What you build

Nothing extra. **DodgeballBallTemplate** adds the physics tag when balls are created or refreshed; arena balls get it on **DodgeballService** load via `applyAppearance`.

## Config

All **`BALL_PHYSICS_*`** and **`BALL_PHYSICS_TAG`** keys in [DodgeballConfig.md](../DodgeballConfig/DodgeballConfig.md).

## Stacking with thrower no-collide (PR #25)

Optional **`DodgeballThrowerCollision`** from PR #25 is independent — paste it alongside this setup. Both touch throws; merge both before play-testing throw feel.