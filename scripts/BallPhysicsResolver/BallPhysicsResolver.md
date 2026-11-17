# BallPhysicsResolver

**Purpose:** Finds the BallPhysics **library entry ModuleScript** under `ReplicatedStorage` so `require()` works in Studio (ModuleScript root vs mistaken Folder).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `BallPhysicsResolver` | `ReplicatedStorage/BallPhysicsResolver` | **ModuleScript** |
| `BallPhysics` | `ReplicatedStorage/BallPhysics` | **ModuleScript** (entry — not a Folder) |

Paste [BallPhysicsResolver.lua](./BallPhysicsResolver.lua) before wiring AutoSetup / Client.

See [ball-physics/README.md](../ball-physics/README.md) for the full child tree under **`BallPhysics`**.