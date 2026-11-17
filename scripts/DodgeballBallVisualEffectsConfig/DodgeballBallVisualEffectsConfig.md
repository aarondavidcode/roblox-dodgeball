# DodgeballBallVisualEffectsConfig

**Purpose:** Tunables for client ball visual effects (**DodgeballBallVisualEffectsClient**). **DodgeballService** mirrors these on `ReplicatedStorage/DodgeballRemotes` so clients never require **ServerScriptService**.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballBallVisualEffectsConfig` | `ServerScriptService/DodgeballBallVisualEffectsConfig` | **ModuleScript** |

Paste from [DodgeballBallVisualEffectsConfig.lua](./DodgeballBallVisualEffectsConfig.lua).

## Config knobs

| Key | Meaning |
|-----|---------|
| `DEFAULT_BALL_VISUAL_EFFECT` | Registry id (default `SpeedGlow`) |
| `BALL_VISUAL_EFFECT_PLAYER_ATTR`, `BALL_VISUAL_EFFECT_BALL_ATTR` | Future per-player / per-ball effect id |
| `SET_BALL_VISUAL_EFFECT_REMOTE_NAME` | Intended RemoteFunction name (not wired) |
| `SPEED_GLOW_HYSTERESIS_FRACTION` | SpeedGlow off threshold = `HIT_MIN_SPEED` × this |
| `SPEED_GLOW_SHELL_DIAMETER_SCALE` | Halo shell = ball diameter × scale |
| `SPEED_GLOW_FILL_TRANSPARENCY`, `SPEED_GLOW_OUTLINE_TRANSPARENCY` | Highlight strength while glowing (lower = more visible) |
| `SPEED_GLOW_SPECTATOR_OUTLINE_COLOR`, `SPEED_GLOW_MIN_OUTLINE_LUMINANCE` | Contrast on pale / white throws (yellow ball) |
| `BALL_VISUAL_EFFECT_SPECTATOR_COLOR` | VFX color with no team thrower |

**Future shell scales:** add `BALL_VISUAL_EFFECT_<EFFECTID>_SHELL_DIAMETER_SCALE` in this module, mirror in **DodgeballService** `publishClientTunables`, read in **DodgeballBallVisualEffectsClient**.

## Related

| Script | Role |
|--------|------|
| [DodgeballService](../DodgeballService/DodgeballService.md) | Mirrors attrs on **DodgeballRemotes** |
| [DodgeballBallVisualEffectsClient](../DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.md) | Client consumer |