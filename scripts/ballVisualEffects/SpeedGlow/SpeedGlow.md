# SpeedGlow

**Purpose:** Subtle **Highlight** on dodgeball Parts when `AssemblyLinearVelocity` is at or above **`HIT_MIN_SPEED`** (from **DodgeballRemotes** attributes). Turns off with hysteresis so the ball does not flicker at the threshold. **FillColor** / **OutlineColor** follow **`context.effectColor`** (thrower team or spectator white).

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `SpeedGlow` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/SpeedGlow` | **ModuleScript** |

Paste from [SpeedGlow.lua](./SpeedGlow.lua). Requires sibling **BallVisualEffectRegistry**.

## Tunables

| Key | Where |
|-----|--------|
| `HIT_MIN_SPEED` | **DodgeballConfig** → mirrored on `ReplicatedStorage/DodgeballRemotes` |
| `SPEED_GLOW_HYSTERESIS_FRACTION` | **DodgeballBallVisualEffectsConfig** → remotes attributes |
| `SPEED_GLOW_SHELL_DIAMETER_SCALE` | Halo size: ball diameter × scale ([BallVisualEffectShell](../BallVisualEffectShell/BallVisualEffectShell.md)) |

Registry id: **`SpeedGlow`** (default `DEFAULT_BALL_VISUAL_EFFECT` in **DodgeballBallVisualEffectsConfig**).