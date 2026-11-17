# SpeedGlow

**Purpose:** Subtle team-colored aura only during an active throw: effective speed `>= HIT_MIN_SPEED` (off below `HIT_MIN_SPEED × SPEED_GLOW_HYSTERESIS_FRACTION`) **and** elapsed since `LastThrowTime` `<= THROW_OUT_WINDOW_SECONDS` — whichever limit is hit first ends the effect. Suppressed while `HolderUserId` is set. Within the window, if client velocity lags, falls back to replicated `LastThrowSpeed`. **Highlight** + **BallVisualEffectShell** + **ParticleEmitter** (parented on the ball Part). Colors via **BallVisualEffectColors**.

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