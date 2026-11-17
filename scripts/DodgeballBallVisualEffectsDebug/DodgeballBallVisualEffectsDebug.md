# DodgeballBallVisualEffectsDebug

**Purpose:** Throw-triggered Output for **SpeedGlow** / ball VFX (tags, remotes tunables, speed, highlight state). Separate from [DodgeballBallPhysicsDebug](../DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md).

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `DodgeballBallVisualEffectsDebug` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/DodgeballBallVisualEffectsDebug` | **ModuleScript** |

Paste from [DodgeballBallVisualEffectsDebug.lua](./DodgeballBallVisualEffectsDebug.lua).

**Optional:** same source under `ServerScriptService/DodgeballBallVisualEffectsDebug` if you want config-side `isEnabled` without remotes (client still uses remotes in play).

## Enable

1. Set **`DEBUG_BALL_VISUAL_EFFECTS = true`** in [DodgeballDebugConfig](../DodgeballDebugConfig/DodgeballDebugConfig.md), re-paste **DodgeballService** + **DodgeballDebugConfig**, **Save** (or play).
2. **Or** at runtime in Studio: `ReplicatedStorage.DodgeballRemotes` attribute **`DEBUG_BALL_VISUAL_EFFECTS`** = **true** (mirror updates on next **DodgeballService** start).

Requires **DodgeballBallVisualEffectsClient** + child modules (same as VFX stack).

## What to copy for Aaron

Filter **View → Output** for **`[DodgeballBallVisualEffectsDebug]`**.

| Line | Meaning |
|------|---------|
| `client start` | Singleton + registry ids + remotes attribute snapshot (`warn` if any VFX attr is `nil`) |
| `throw sample +0s` | Ball tracked, tags, effect id, tunables, speed, `shouldGlow`, highlight state, shell |
| `throw sample +0.35s` / `+1s` | Same after flight (client physics) |

Throw samples only for **your** throws (`LastThrowerUserId` = local player).

## Typical causes when glow missing

- **`HIT_MIN_SPEED` or shell scale `nil` on remotes** — missing **DodgeballBallVisualEffectsConfig** or old **DodgeballService** (re-paste both).
- **Ball not tracked** — missing `PhysicsBall` / `Dodgeball` / `LobbyPracticeBall` tag on client.
- **`shouldGlow=false`** while speed high — check replicated `HIT_MIN_SPEED` vs measured speed.
- **`highlight.Enabled=false`** while `shouldGlow=true`** — SpeedGlow bug (file an issue with sample block).