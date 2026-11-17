# BallPhysics (vendored)

Third-party library: [thaalish/ball-physics](https://github.com/thaalish/ball-physics) **v1.0.0** (`SOURCE_COMMIT` in this folder).

- **License:** MIT — see [LICENSE](./LICENSE).
- **Upstream pin:** [VERSION](./VERSION)

Game tuning lives in **DodgeballConfig** (`BALL_PHYSICS_*`); **BallPhysicsAutoSetup** applies it to `BallPhysics.Config` at server start.

## Studio: required Explorer hierarchy

**`ReplicatedStorage/BallPhysics` must be a ModuleScript** (library entry).  
Do **not** insert a **Folder** named `BallPhysics` and `require()` it — Roblox will error (`Attempted to call require with invalid argument(s)`).

```
ReplicatedStorage
└── BallPhysics                  [ModuleScript]  ← paste scripts/ball-physics/src/init.luau HERE (not a Folder)
    ├── Config                   [ModuleScript]  ← src/Config.luau
    ├── Types                    [ModuleScript]  ← src/Types.luau
    ├── AlarmClock               [ModuleScript]  ← src/AlarmClock.luau
    ├── Effects                  [Folder]
    │   ├── init                 [ModuleScript]  ← Effects/init.luau
    │   ├── AntiGravity          [ModuleScript]
    │   ├── AngularDamping       [ModuleScript]
    │   ├── KnuckleBall          [ModuleScript]
    │   └── MagnusEffect         [ModuleScript]
    └── Runtime                  [Folder]
        ├── Client               [ModuleScript]
        ├── Server               [ModuleScript]
        ├── Simulator            [ModuleScript]
        └── Util                 [ModuleScript]
```

If you already have a **Folder** named `BallPhysics`:

1. Create a **ModuleScript** also named `BallPhysics` under `ReplicatedStorage` (sibling to the Folder).
2. Move all library children **inside** that ModuleScript (Config, Effects, Runtime, …).
3. Paste `init.luau` source into the **ModuleScript** body.
4. Delete the empty Folder.

**Wrong (breaks `require`):** `Config` / `Effects` as direct children of a Folder named `BallPhysics`.

## File map (GitHub → Studio)

| GitHub path | Studio child of **BallPhysics** ModuleScript |
|-------------|---------------------------------------------|
| `scripts/ball-physics/src/init.luau` | **Source of** `ReplicatedStorage/BallPhysics` ModuleScript |
| `scripts/ball-physics/src/Config.luau` | `Config` ModuleScript |
| `scripts/ball-physics/src/Types.luau` | `Types` ModuleScript |
| `scripts/ball-physics/src/AlarmClock.luau` | `AlarmClock` ModuleScript |
| `scripts/ball-physics/src/Effects/*.luau` | Under `Effects/` folder |
| `scripts/ball-physics/src/Runtime/*.luau` | Under `Runtime/` folder |

Then paste **BallPhysicsAutoSetup** (server Script) and **BallPhysicsClient** (LocalScript) from this repo — see root [README.md](../../README.md).

## Tags and dodgeballs

The library tracks parts tagged with **`DODGEBALL_BALL_PHYSICS_TAG`** in DodgeballConfig (default `PhysicsBall`). **DodgeballBallTemplate** adds that tag whenever appearance is applied; arena and lobby practice balls keep their existing **`Dodgeball`** / **`LobbyPracticeBall`** tags.

## Debug (off in production)

Upstream supports F3/F4 debug in `dev/` only (not vendored here). **`BALL_PHYSICS_DEBUG_ENABLED`** in [DodgeballDebugConfig.md](../DodgeballDebugConfig/DodgeballDebugConfig.md) stays `false` by default. Use **`DEBUG_BALL_PHYSICS`** there for integration Output — see [DodgeballBallPhysicsDebug.md](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md).