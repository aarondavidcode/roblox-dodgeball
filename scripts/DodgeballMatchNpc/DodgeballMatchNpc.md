# DodgeballMatchNpc

**Purpose:** Server-side test NPC registry for single-player Studio matches. Humanoid rigs are balanced onto Red/Blue with [TeamAutoBalance](../TeamAutoBalance/TeamAutoBalance.md), can be eliminated like players, and wander randomly in the arena.

**Enabled when:** [DodgeballDebugConfig](../DodgeballDebugConfig/DodgeballDebugConfig.md) `SINGLE_PLAYER_TESTING` and a match started via [DodgeballSinglePlayerTest](../DodgeballSinglePlayerTest/DodgeballSinglePlayerTest.md).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballMatchNpc` | `ServerScriptService/DodgeballMatchNpc` | **ModuleScript** |

Paste from [DodgeballMatchNpc.lua](./DodgeballMatchNpc.lua).

NPC bodies live under `Workspace/DodgeballTestNpcs` while a test match is active.

### Walk animation (optional)

Server rigs do not run the client **Animate** script. For walk cycles in Studio, add an **Animation** instance named **`DodgeballTestNpcWalk`** under **ServerStorage** (or **ReplicatedStorage**) using a walk clip **owned by your experience** — Studio blocks untrusted default `rbxassetid` walks. If missing, NPCs still move via `MoveTo` without playing a walk track.

## Related

| Script | Role |
|--------|------|
| [TeamAutoBalance](../TeamAutoBalance/TeamAutoBalance.md) | Balances players + NPCs by `UserId` / `NpcSortId` |
| [DodgeballService](../DodgeballService/DodgeballService.md) | Throw elimination on NPC rigs |
| [RoundService](../RoundService/RoundService.md) | Team-all-OUT win checks include NPCs |
| [LobbyService](../LobbyService/LobbyService.md) | Arena spawn / cleanup on lobby phase |