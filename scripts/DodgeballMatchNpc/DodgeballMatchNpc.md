# DodgeballMatchNpc

**Purpose:** Server-side test NPC registry for single-player Studio matches. Humanoid rigs are balanced onto Red/Blue with [TeamAutoBalance](../TeamAutoBalance/TeamAutoBalance.md), can be eliminated like players, and wander randomly in the arena.

**Enabled when:** [DodgeballDebugConfig](../DodgeballDebugConfig/DodgeballDebugConfig.md) `SINGLE_PLAYER_TESTING` and a match started via [DodgeballSinglePlayerTest](../DodgeballSinglePlayerTest/DodgeballSinglePlayerTest.md).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballMatchNpc` | `ServerScriptService/DodgeballMatchNpc` | **ModuleScript** |

Paste from [DodgeballMatchNpc.lua](./DodgeballMatchNpc.lua).

NPC bodies live under `Workspace/DodgeballTestNpcs` while a test match is active.

## Related

| Script | Role |
|--------|------|
| [TeamAutoBalance](../TeamAutoBalance/TeamAutoBalance.md) | Balances players + NPCs by `UserId` / `NpcSortId` |
| [DodgeballService](../DodgeballService/DodgeballService.md) | Throw elimination on NPC rigs |
| [RoundService](../RoundService/RoundService.md) | Team-all-OUT win checks include NPCs |
| [LobbyService](../LobbyService/LobbyService.md) | Arena spawn / cleanup on lobby phase |