# DodgeballBallVisualEffectsConfig

**Purpose:** Tunables for client ball visual effects (**DodgeballBallVisualEffectsClient**). **DodgeballService** mirrors these on `ReplicatedStorage/DodgeballRemotes` so clients never require **ServerScriptService**.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballBallVisualEffectsConfig` | `ServerScriptService/DodgeballBallVisualEffectsConfig` | **ModuleScript** |

Paste from [DodgeballBallVisualEffectsConfig.lua](./DodgeballBallVisualEffectsConfig.lua).

## SpeedGlow renderer choice (brief)

Client-only, team-colored, scalable halos on fast-moving sphere Parts:

| Approach | Verdict |
|----------|---------|
| **Highlight** | We tried this first. Fill/outline on pale yellow balls stayed invisible or flickered; `Adornee` + welded shells + `AlwaysOnTop` still unreliable in Studio play. Not our primary renderer. |
| **Highlight + ForceField shell + Part particles** | **Primary for SpeedGlow.** Outline/shell when speed ≥ `HIT_MIN_SPEED`; team tint from **BallVisualEffectColors**. Particles parent on the ball Part (not Attachment). Optional shell scale from `SPEED_GLOW_SHELL_DIAMETER_SCALE`. |
| **PointLight** | Simple, team `Color`, but flat lighting and weak on bright outdoor maps; no silhouette halo. Good future accent, not main trail. |
| **BillboardGui + ImageLabel** | Always faces camera and tints easily, but 2D sticker on a 3D ball; depth/occlusion quirks. Better for icons than speed aura. |
| **SelectionBox / ForceField shell** | Visible shell possible, but extra welded Part + material tricks; heavier than particles and still fights camera depth. **BallVisualEffectShell** remains available for other registry effects. |

## Config knobs

| Key | Meaning |
|-----|---------|
| `DEFAULT_BALL_VISUAL_EFFECT` | Registry id (default `SpeedGlow`) |
| `BALL_VISUAL_EFFECT_PLAYER_ATTR`, `BALL_VISUAL_EFFECT_BALL_ATTR` | Future per-player / per-ball effect id |
| `SET_BALL_VISUAL_EFFECT_REMOTE_NAME` | Intended RemoteFunction name (not wired) |
| `SPEED_GLOW_HYSTERESIS_FRACTION` | Glow off below `HIT_MIN_SPEED ×` this (default 0.92) |
| `SPEED_GLOW_SHELL_DIAMETER_SCALE` | Halo diameter multiplier (used with particle size) |
| `SPEED_GLOW_PARTICLE_RATE` | Emitter rate while glowing |
| `SPEED_GLOW_PARTICLE_SIZE_SCALE` | Particle size = ball diameter × shell scale × this |
| `SPEED_GLOW_PARTICLE_LIGHT_EMISSION`, `SPEED_GLOW_PARTICLE_TRANSPARENCY` | Brightness / alpha |
| `SPEED_GLOW_SPECTATOR_OUTLINE_COLOR`, `SPEED_GLOW_MIN_OUTLINE_LUMINANCE` | Contrast for pale throw colors |
| `BALL_VISUAL_EFFECT_SPECTATOR_COLOR` | VFX color with no team thrower |

**Future shell scales:** add `BALL_VISUAL_EFFECT_<EFFECTID>_SHELL_DIAMETER_SCALE` in this module, mirror in **DodgeballService** `publishClientTunables`, read in **DodgeballBallVisualEffectsClient**.

## Checklist after editing this file

1. Re-paste **`ServerScriptService/DodgeballBallVisualEffectsConfig`** (this module).
2. Re-paste **`ServerScriptService/DodgeballService`** so `publishClientTunables` mirrors new keys on **DodgeballRemotes**.
3. If defaults changed, update **`ballVisualEffects/BallVisualEffectRemoteDefaults`** on the client (same numbers).
4. **Play** (or re-publish) so the server runs the updated service once.

## Remotes attributes mirrored (SpeedGlow)

`DEFAULT_BALL_VISUAL_EFFECT`, `SPEED_GLOW_HYSTERESIS_FRACTION`, `SPEED_GLOW_SHELL_DIAMETER_SCALE`, `SPEED_GLOW_PARTICLE_RATE`, `SPEED_GLOW_PARTICLE_SIZE_SCALE`, `SPEED_GLOW_PARTICLE_LIGHT_EMISSION`, `SPEED_GLOW_PARTICLE_TRANSPARENCY`, `SPEED_GLOW_MIN_OUTLINE_LUMINANCE`, `SPEED_GLOW_SPECTATOR_OUTLINE_COLOR`, `BALL_VISUAL_EFFECT_SPECTATOR_COLOR`, `BALL_VISUAL_EFFECT_BALL_ATTR`, `BALL_VISUAL_EFFECT_PLAYER_ATTR`

## Related

| Script | Role |
|--------|------|
| [DodgeballService](../DodgeballService/DodgeballService.md) | Mirrors attrs on **DodgeballRemotes** |
| [DodgeballBallVisualEffectsClient](../DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.md) | Client consumer |