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

## Depends on (auto-created)

| Object | Source |
|--------|--------|
| `ReplicatedStorage/DodgeballRemotes` | **DodgeballService** — attributes: `HIT_MIN_SPEED`, `DEFAULT_BALL_VISUAL_EFFECT`, `SPEED_GLOW_HYSTERESIS_FRACTION`, tag names, effect attribute names |

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