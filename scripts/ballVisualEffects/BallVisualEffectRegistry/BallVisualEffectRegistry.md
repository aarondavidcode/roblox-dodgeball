# BallVisualEffectRegistry

**Purpose:** Client-side map from effect **id** string → effect **ModuleScript**. **DodgeballBallVisualEffectsClient** registers built-in effects here.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `ballVisualEffects` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects` | **Folder** |
| `BallVisualEffectRegistry` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectRegistry` | **ModuleScript** |

Paste from [BallVisualEffectRegistry.lua](./BallVisualEffectRegistry.lua).

## Add another effect later

1. Add a new **ModuleScript** next to `SpeedGlow` under `ballVisualEffects` (e.g. `TrailBurst`).
2. Export `{ id = "TrailBurst", attach, detach, step }` matching **SpeedGlow**.
3. In **DodgeballBallVisualEffectsClient**, `require` the module and call `Registry.register(...)`.
4. Optionally set `DEFAULT_BALL_VISUAL_EFFECT` in **DodgeballConfig** or set player/ball attributes (see [DodgeballBallVisualEffectsClient.md](../../DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.md)).