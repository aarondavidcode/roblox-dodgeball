# DodgeballBallVisualEffectsClient

**Purpose:** Tracks arena + lobby dodgeballs (same tags as **BallPhysicsAutoSetup** / **DodgeballBallTemplate**) and runs registered visual effects each frame. Default effect: **SpeedGlow** at throw speed.

## Studio paste

| Instance | Explorer path | Type |
|----------|---------------|------|
| `DodgeballBallVisualEffectsClient` | `StarterPlayer/StarterPlayerScripts/DodgeballBallVisualEffectsClient` | **LocalScript** |
| `ballVisualEffects` | `StarterPlayer/StarterPlayerScripts/ballVisualEffects` | **Folder** |

Paste from [DodgeballBallVisualEffectsClient.local.lua](./DodgeballBallVisualEffectsClient.local.lua).

Child modules (required):

| Module | Doc |
|--------|-----|
| `ballVisualEffects/BallVisualEffectRegistry` | [BallVisualEffectRegistry.md](../ballVisualEffects/BallVisualEffectRegistry/BallVisualEffectRegistry.md) |
| `ballVisualEffects/SpeedGlow` | [SpeedGlow.md](../ballVisualEffects/SpeedGlow/SpeedGlow.md) |
| `ballVisualEffects/BallVisualEffectColors` | [BallVisualEffectColors.md](../ballVisualEffects/BallVisualEffectColors/BallVisualEffectColors.md) |
| `ballVisualEffects/BallVisualEffectShell` | [BallVisualEffectShell.md](../ballVisualEffects/BallVisualEffectShell/BallVisualEffectShell.md) |
| `ballVisualEffects/DodgeballBallVisualEffectsDebug` | [DodgeballBallVisualEffectsDebug.md](../DodgeballBallVisualEffectsDebug/DodgeballBallVisualEffectsDebug.md) |
| `ballVisualEffects/BallVisualEffectRemoteDefaults` | [BallVisualEffectRemoteDefaults.md](../ballVisualEffects/BallVisualEffectRemoteDefaults/BallVisualEffectRemoteDefaults.md) |

## Depends on (auto-created)

| Object | Source |
|--------|--------|
| `ReplicatedStorage/DodgeballRemotes` | **DodgeballService** — attributes: `HIT_MIN_SPEED`, `DEFAULT_BALL_VISUAL_EFFECT`, `SPEED_GLOW_HYSTERESIS_FRACTION`, `BALL_VISUAL_EFFECT_SPECTATOR_COLOR`, tag names, effect attribute names |

## Which balls get effects

CollectionService tags (from config, mirrored on remotes):

- `DODGEBALL_TAG` (arena)
- `LOBBY_PRACTICE_BALL_TAG` (lobby practice)
- `BALL_PHYSICS_TAG` (all template balls — same tracking idea as **BallPhysicsAutoSetup**)

## Future per-player effect choice

Not implemented on the server yet. Extension points in **DodgeballConfig**:

| Key | Role |
|-----|------|
| `BALL_VISUAL_EFFECT_PLAYER_ATTR` | Player attribute holding effect id (e.g. after a shop UI) |
| `BALL_VISUAL_EFFECT_BALL_ATTR` | Optional override on the ball |
| `SET_BALL_VISUAL_EFFECT_REMOTE_NAME` | Intended **RemoteFunction** name under `DodgeballRemotes` for validated updates |

**Client resolution order today:** ball override → thrower `LastThrowerUserId` player attribute → `DEFAULT_BALL_VISUAL_EFFECT`.

When you wire the server, create the RemoteFunction, validate ids against the same registry list you register in this LocalScript, and set the player attribute.

## Team-based effect color

Built each frame in **BallVisualEffectColors** and passed on `EffectContext`:

| Field | Meaning |
|-------|---------|
| `effectColor` | `thrower.Team.TeamColor.Color` when `LastThrowerUserId` points at a player on a team; else `BALL_VISUAL_EFFECT_SPECTATOR_COLOR` |
| `teamName` | Explorer **Team** `.Name` when resolved; else `nil` |
| `throwerUserId` | Attribute value when present; else `nil` |

Works for any team names in Explorer — not tied to `TEAM_NAMES`. Re-throws update color when `LastThrowerUserId` changes (each **Heartbeat** `step`).

## Shell halo size

`EffectContext.shell.diameterScale` is set per active effect id (`shellDiameterScaleForEffect` in the LocalScript). **SpeedGlow** uses **BallVisualEffectShell** and adorns the shell with **Highlight**. Sphere dodgeballs only; non-spheres fall back to highlighting the ball Part.

**Another effect / scale:** add `BALL_VISUAL_EFFECT_<EFFECTID>_SHELL_DIAMETER_SCALE` in **DodgeballBallVisualEffectsConfig**, mirror on remotes, extend `shellDiameterScaleForEffect`, and call `BallVisualEffectShell.create(ball, effectId, context.shell.diameterScale)` in the effect module.