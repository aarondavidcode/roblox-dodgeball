# SpeedGlow

**Purpose:** **ParticleEmitter** on a ball **Attachment** when `AssemblyLinearVelocity` is at or above **`HIT_MIN_SPEED`** (from **DodgeballRemotes**). Team/spectator color via **BallVisualEffectColors**. Uses hysteresis so the effect does not flicker at the threshold.

Replaced **Highlight** + shell (see [DodgeballBallVisualEffectsConfig.md](../../DodgeballBallVisualEffectsConfig/DodgeballBallVisualEffectsConfig.md) renderer notes).

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `SpeedGlow` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/SpeedGlow` | **ModuleScript** |

Paste from [SpeedGlow.lua](./SpeedGlow.lua). Requires sibling **BallVisualEffectRegistry**.

## Tunables

| Key | Where |
|-----|--------|
| `HIT_MIN_SPEED` | **DodgeballConfig** → mirrored on `ReplicatedStorage/DodgeballRemotes` |
| `SPEED_GLOW_HYSTERESIS_FRACTION` | **DodgeballBallVisualEffectsConfig** → remotes |
| `SPEED_GLOW_SHELL_DIAMETER_SCALE` | Diameter multiplier (with particle size scale) |
| `SPEED_GLOW_PARTICLE_*` | Rate, size scale, light emission, transparency |

Registry id: **`SpeedGlow`** (default `DEFAULT_BALL_VISUAL_EFFECT` in **DodgeballBallVisualEffectsConfig**).