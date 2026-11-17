# BallVisualEffectColors

**Purpose:** One place on the client to turn a dodgeball Part into **`effectColor`** (+ optional thrower / team metadata). Works for **any** Explorer **Team** name — color comes from `Player.Team.TeamColor.Color`, not hard-coded Red/Blue.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `BallVisualEffectColors` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectColors` | **ModuleScript** |

Paste from [BallVisualEffectColors.lua](./BallVisualEffectColors.lua).

## Rules

| Situation | Color |
|-----------|--------|
| No `LastThrowerUserId`, or id ≤ 0 | `BALL_VISUAL_EFFECT_SPECTATOR_COLOR` (from **DodgeballRemotes**) |
| Thrower left the server | Spectator color |
| Thrower has no **Team** (lobby spectator, neutral) | Spectator color |
| Thrower on a team | `thrower.Team.TeamColor.Color` |

**DodgeballBallVisualEffectsClient** calls `resolveForBall` each `attach` / `step` so re-throws update when `LastThrowerUserId` changes.

## For new effects

Read **`context.effectColor`** (and optional `context.teamName`) from [BallVisualEffectRegistry](../BallVisualEffectRegistry/BallVisualEffectRegistry.md) `EffectContext`. **SpeedGlow** uses `colorsForGlow` for pale/white fills (cyan rim from `SPEED_GLOW_SPECTATOR_OUTLINE_COLOR`) — do not re-implement team lookup in the effect module.