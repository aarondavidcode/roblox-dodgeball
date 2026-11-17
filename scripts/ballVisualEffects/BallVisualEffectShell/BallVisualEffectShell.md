# BallVisualEffectShell

**Purpose:** Client-only **transparent** sphere welded to a dodgeball Part. Larger **Highlight** / halo visuals without affecting physics, pickup, or hit detection.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `BallVisualEffectShell` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectShell` | **ModuleScript** |

Paste from [BallVisualEffectShell.lua](./BallVisualEffectShell.lua).

## API

```lua
local handle = BallVisualEffectShell.create(ball, "SpeedGlow", context.shell.diameterScale)
handle.part -- adorn Highlights here
handle.setDiameterScale(newScale) -- when tunables change
handle.destroy() -- on effect detach
```

Returns **`nil`** if the ball is not a **Ball** shape (falls back to adorning the ball in that effect).

## Properties (shell Part)

| Property | Value |
|----------|--------|
| `CanCollide` / `CanTouch` / `CanQuery` | `false` |
| `Massless` | `true` |
| `Transparency` | `1` |
| Attachment | **WeldConstraint** to the ball |

## Scale tunables

Diameter = ball diameter × **`context.shell.diameterScale`**. Scale comes from **DodgeballBallVisualEffectsConfig** per effect (mirrored on **DodgeballRemotes**) — see **SpeedGlow** `SPEED_GLOW_SHELL_DIAMETER_SCALE`.

**Future effects:** add `BALL_VISUAL_EFFECT_<EFFECTID>_SHELL_DIAMETER_SCALE` in **DodgeballBallVisualEffectsConfig** (e.g. `BALL_VISUAL_EFFECT_TRAILBURST_SHELL_DIAMETER_SCALE`), mirror on remotes, and read it in **DodgeballBallVisualEffectsClient** when building `EffectContext.shell` for that effect id.