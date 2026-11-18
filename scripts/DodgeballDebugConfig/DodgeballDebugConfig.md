# DodgeballDebugConfig

**Purpose:** Debug and diagnostics flags. Defaults are **off** for published games.

**Gameplay:** Every flag here is **diagnostics only**. Throws, pickups, eliminations, and BallPhysics/VFX behavior must be identical whether these are `true` or `false`. If toggling a debug flag changes gameplay, that is a bug — fix the throw/physics path, not by leaving debug on.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballDebugConfig` | `ServerScriptService/DodgeballDebugConfig` | **ModuleScript** |

Paste from [DodgeballDebugConfig.lua](./DodgeballDebugConfig.lua).

## Config knobs

| Key | Meaning |
|-----|---------|
| `DEBUG_ELIMINATION` | **DodgeballService** warns why a hit did not eliminate |
| `DEBUG_BALL_PHYSICS` | **[DodgeballBallPhysicsDebug](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md)** tagged Output; mirrored on **DodgeballRemotes** |
| `BALL_PHYSICS_DEBUG_ENABLED` | Vendored BallPhysics `Config.debug.enabled` in **BallPhysicsAutoSetup** |
| `DEBUG_BALL_VISUAL_EFFECTS` | [DodgeballBallVisualEffectsDebug](../DodgeballBallVisualEffectsDebug/DodgeballBallVisualEffectsDebug.md) throw / glow Output; mirrored on **DodgeballRemotes** |
| `SINGLE_PLAYER_TESTING` | Enables [DodgeballSinglePlayerTest](../DodgeballSinglePlayerTest/DodgeballSinglePlayerTest.md) chat commands and [DodgeballMatchNpc](../DodgeballMatchNpc/DodgeballMatchNpc.md). **Off** in published places. |

For local Studio without editing this file, you can set `DodgeballRemotes` attribute **`DEBUG_BALL_PHYSICS`** = **true** at runtime (server still mirrors config on start).

## Related

| Script | Role |
|--------|------|
| [DodgeballService](../DodgeballService/DodgeballService.md) | `DEBUG_ELIMINATION`, mirrors `DEBUG_BALL_PHYSICS` |
| [DodgeballBallPhysicsDebug](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md) | Reads `DEBUG_BALL_PHYSICS` |
| [BallPhysicsAutoSetup](../BallPhysicsAutoSetup/BallPhysicsAutoSetup.md) | Reads `BALL_PHYSICS_DEBUG_ENABLED` |