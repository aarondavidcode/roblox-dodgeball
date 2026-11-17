# BallPhysicsClient

**Purpose:** Starts the BallPhysics **client** replication singleton so thrown balls can simulate on the owning client (library handles handoff).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `BallPhysicsResolver` | `ReplicatedStorage/BallPhysicsResolver` | **ModuleScript** |
| `BallPhysics` | `ReplicatedStorage/BallPhysics` | **ModuleScript** entry — [ball-physics README](../ball-physics/README.md) |
| `BallPhysicsClient` | `StarterPlayer/StarterPlayerScripts/BallPhysicsClient` | **LocalScript** |

Paste from [BallPhysicsClient.local.lua](./BallPhysicsClient.local.lua).

No config knobs. Do **not** paste upstream `dev/Debug.client.luau` for F3/F4 unless you explicitly want dev overlays (`BALL_PHYSICS_DEBUG_ENABLED` does not wire those scripts in this repo).