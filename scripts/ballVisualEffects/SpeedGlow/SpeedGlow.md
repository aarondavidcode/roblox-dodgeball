# SpeedGlow

**Purpose:** Subtle team-colored aura only while the ball **can still eliminate** ([**BallVisualEffectThrowState**](../BallVisualEffectThrowState/BallVisualEffectThrowState.md)) **and** effective speed `>= HIT_MIN_SPEED` (hysteresis off at `HIT_MIN_SPEED × SPEED_GLOW_HYSTERESIS_FRACTION`). Suppressed while held. Uses `resolveEffectiveThrowSpeed` when client velocity lags. **Highlight** + **BallVisualEffectShell** + **ParticleEmitter** (parented on the ball Part). Colors via **BallVisualEffectColors**.

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