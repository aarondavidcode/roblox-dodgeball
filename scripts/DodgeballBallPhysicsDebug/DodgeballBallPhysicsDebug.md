# DodgeballBallPhysicsDebug

**Purpose:** Temporary **Output** diagnostics for BallPhysics integration. Off by default.

## Enable (no full repaste hunt)

Set **`DEBUG_BALL_PHYSICS = true`** in **DodgeballConfig**, **or** in Studio while running set  
`ReplicatedStorage.DodgeballRemotes` attribute **`DEBUG_BALL_PHYSICS`** = **true** (server mirrors config on start).

Filter Output: **`[DodgeballBallPhysicsDebug]`**

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballBallPhysicsDebug` | `ServerScriptService/DodgeballBallPhysicsDebug` | **ModuleScript** |

Paste from [DodgeballBallPhysicsDebug.lua](./DodgeballBallPhysicsDebug.lua).

## Aaron test → paste back

1. Enable debug (config or remotes attribute). Play (**F5** or 2 Players).
2. Walk to ball → pick up → aim to **≥50% power** → release throw.
3. Copy **every** `[DodgeballBallPhysicsDebug]` line from **pickup** through **~2 seconds after release** (server + client Output if testing multiplayer).

Look for: `PhysicsBall` tag, AutoSetup handler created, hold/release owner, impulse + spin, effects enabled, client `isOwned`, and any **warn** about missing module/scripts/tags.