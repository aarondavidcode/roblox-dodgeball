# BallPhysics (vendored)

Third-party library: [thaalish/ball-physics](https://github.com/thaalish/ball-physics) **v1.0.0** (`SOURCE_COMMIT` in this folder).

- **License:** MIT — see [LICENSE](./LICENSE).
- **Upstream pin:** [VERSION](./VERSION)

Game tuning lives in **DodgeballConfig** (`BALL_PHYSICS_*`); **BallPhysicsAutoSetup** applies it to `BallPhysics.Config` at server start.

## Studio: paste the module tree

Create a **Folder** (or keep modules as siblings — names must match `require()` paths) under **`ReplicatedStorage/BallPhysics`**:

| GitHub path | Explorer path | Type |
|-------------|---------------|------|
| `scripts/ball-physics/src/init.luau` | `ReplicatedStorage/BallPhysics` | **ModuleScript** (root entry) |
| `scripts/ball-physics/src/Config.luau` | `ReplicatedStorage/BallPhysics/Config` | ModuleScript |
| `scripts/ball-physics/src/Types.luau` | `ReplicatedStorage/BallPhysics/Types` | ModuleScript |
| `scripts/ball-physics/src/AlarmClock.luau` | `ReplicatedStorage/BallPhysics/AlarmClock` | ModuleScript |
| `scripts/ball-physics/src/Effects/` (each `.luau`) | `ReplicatedStorage/BallPhysics/Effects/...` | ModuleScripts (`init`, `AntiGravity`, `AngularDamping`, `KnuckleBall`, `MagnusEffect`) |
| `scripts/ball-physics/src/Runtime/` (each `.luau`) | `ReplicatedStorage/BallPhysics/Runtime/...` | ModuleScripts (`Client`, `Server`, `Simulator`, `Util`) |

Paste file contents into each ModuleScript (Luau strict mode is fine in Studio).

Then paste **BallPhysicsAutoSetup** (server Script) and **BallPhysicsClient** (LocalScript) from this repo — see root [README.md](../../README.md).

## Tags and dodgeballs

The library tracks parts tagged with **`DODGEBALL_BALL_PHYSICS_TAG`** in DodgeballConfig (default `PhysicsBall`). **DodgeballBallTemplate** adds that tag whenever appearance is applied; arena and lobby practice balls keep their existing **`Dodgeball`** / **`LobbyPracticeBall`** tags.

## Debug (off in production)

Upstream supports F3/F4 debug in `dev/` only (not vendored here). **`BALL_PHYSICS_DEBUG_ENABLED`** in DodgeballConfig stays `false` by default.