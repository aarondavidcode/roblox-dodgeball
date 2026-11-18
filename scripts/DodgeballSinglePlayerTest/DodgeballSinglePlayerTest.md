# DodgeballSinglePlayerTest

**Purpose:** Chat commands to start an arena match with one human player plus test NPCs (Studio debug).

## Explorer

| Object | Path | Type |
|--------|------|------|
| `DodgeballSinglePlayerTest` | `ServerScriptService/DodgeballSinglePlayerTest` | **Script** |

Paste from [DodgeballSinglePlayerTest.server.lua](./DodgeballSinglePlayerTest.server.lua).

## Setup

1. Set **`SINGLE_PLAYER_TESTING = true`** in [DodgeballDebugConfig](../DodgeballDebugConfig/DodgeballDebugConfig.md).
2. Paste **LobbyService**, **TeamAutoBalance**, **DodgeballService**, **RoundService**, **DodgeballMatchNpc**, and this script (or sync via Rojo).
3. Play with **F5** (one client).

## Commands

| Chat | Action |
|------|--------|
| `/testmatch` | Start match with **3** NPCs (default) |
| `/testmatch 5` | Start match with **5** NPCs (1–15) |
| `/starttest` / `/starttest 7` | Alias for `/testmatch` |
| `/testhelp` | Prints command summary to **Output** |

Match must be in **Lobby** phase. NPCs are removed when the match returns to lobby.

## Related

- [DodgeballMatchNpc](../DodgeballMatchNpc/DodgeballMatchNpc.md)
- [DodgeballDebugConfig](../DodgeballDebugConfig/DodgeballDebugConfig.md)