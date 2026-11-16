# RoundStatusClient

**Purpose:** Optional HUD text for lobby countdown, match score, round state, and intermission. Reads attributes on `ReplicatedStorage/RoundStatus` and updates one label.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `RoundStatus` | `StarterGui/RoundStatus` | **ScreenGui** (you create) |
| `CountdownLabel` | `StarterGui/RoundStatus/CountdownLabel` | **TextLabel** |
| `RoundStatusClient` | `StarterGui/RoundStatus/RoundStatusClient` | **LocalScript** |

Paste script from [scripts/RoundStatusClient.local.lua](../scripts/RoundStatusClient.local.lua).

## What you build in Studio

```
StarterGui
  RoundStatus          ← ScreenGui
    CountdownLabel     ← TextLabel (leave Text empty)
    RoundStatusClient  ← LocalScript
```

**CountdownLabel** suggestions (adjust in Properties):

- **Size** ~ `{0.55, 0}, {0.08, 0}` scale; **Position** top center
- **BackgroundTransparency** ~ `0.3`, **TextScaled** on
- Name must be exactly `CountdownLabel`

## What scripts create (do not duplicate)

| Item | Source |
|------|--------|
| `ReplicatedStorage/RoundStatus` | **LobbyService** / **RoundService** |
| Text content | This LocalScript only |

## Attributes read (written by server)

| Attribute | Meaning |
|-----------|---------|
| `MatchPhase` | `Lobby` or `InMatch` |
| `MatchScore_Red`, `MatchScore_Blue` | Match points |
| `MatchPointsToWin` | Usually 3 |
| `LobbyCountdownEndsAt`, `LobbyOptedInCount` | Lobby timer |
| `RoundState`, `RoundNumber`, `IntermissionEndsAt` | Arena round |

## Config / teams

Uses team names `Red` and `Blue` in display logic — keep aligned with `TEAM_NAMES` in **DodgeballConfig**.

## What not to build

Do not rename the ScreenGui or label without updating the LocalScript. Do not expect lobby join UI here — use [LobbyJoinNextMatchClient.md](LobbyJoinNextMatchClient.md).