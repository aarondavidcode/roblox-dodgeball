# LobbyJoinNextMatchClient

**Purpose:** Bottom-bar button to toggle **Joining next match** vs **Spectating**. Fires the server remote so **LobbyService** can count opt-in players for the lobby countdown.

## Explorer

| Object | Path | Type |
|--------|------|------|
| `LobbyJoinNextMatchClient` | `StarterPlayer/StarterPlayerScripts/LobbyJoinNextMatchClient` | **LocalScript** |

Paste from [LobbyJoinNextMatchClient.client.lua](./LobbyJoinNextMatchClient.client.lua).

**Repo:** GitHub folder `scripts/<Name>/` is for organization only. Paste by **Explorer path** in the table (instance **name** must match). ModuleScripts use `require()` by instance name — not repo paths.

## What you build in Studio

Only the LocalScript in **StarterPlayerScripts**. One instance, exact name.

## What scripts create at run time (do not duplicate)

| UI | Under | Pieces |
|----|--------|--------|
| `JoinNextMatch` | `PlayerGui` | ScreenGui |
| `BottomBar` | Inside above | `OptInToggle` button, `QueueHint` (fades after first use) |

## Server / data it expects

| Item | Source |
|------|--------|
| `DodgeballRemotes/SetJoinNextMatch` | **LobbyService** (folder started by **DodgeballService**) |
| `RoundStatus` → `MatchPhase` | Hides bar during **InMatch** for active players; may show for lobby spectators |
| Player `JoinNextMatch` attribute | Same name as `JOIN_NEXT_MATCH_ATTR` in **DodgeballConfig** |

Hardcoded names in the script (`JoinNextMatch`, `SetJoinNextMatch`, `DodgeballRemotes`, `RoundStatus`) should match config defaults.

## Visibility (summary)

| Situation | Bar |
|-----------|-----|
| Lobby, Neutral | Visible |
| **InMatch**, playing | Hidden |
| **InMatch**, spectator on lobby | Visible (queues **next** match) |

## What not to build

Do not hand-build `JoinNextMatch` in **StarterGui**. Do not create the `SetJoinNextMatch` RemoteEvent.