# Scripts folder

Copy these into **Roblox Studio** when a guide tells you to. Server scripts go under **ServerScriptService** unless noted.

## TeamAutoBalance.server.lua

1. Under **ServerScriptService**, insert a **Script** (not LocalScript).
2. Rename it **`TeamAutoBalance`**.
3. Copy from **[TeamAutoBalance.server.lua](TeamAutoBalance.server.lua)**.

Walkthrough: **[03-add-your-first-script](../03-add-your-first-script/README.md)**.

---

## Dodgeball system (step 4)

| Repo file | Studio object | Type |
|-----------|---------------|------|
| [DodgeballConfig.lua](DodgeballConfig.lua) | `DodgeballConfig` | ModuleScript |
| [DodgeballService.server.lua](DodgeballService.server.lua) | `DodgeballService` | Script |
| [throw/DefaultThrow.lua](throw/DefaultThrow.lua) | `throw/DefaultThrow` | ModuleScript |
| [DodgeballThrowInput.local.lua](DodgeballThrowInput.local.lua) | `DodgeballThrowInput` under **StarterPlayerScripts** | **LocalScript** |

Walkthrough: **[04-balls-and-throwing](../04-balls-and-throwing/README.md)** (aim, power charge, hold timer, and UI names).

Default throw lives in **`throw/`** so you can add more **ModuleScripts** later and switch **`ACTIVE_THROW_PROFILE`** in **DodgeballConfig**.

---

## Round reset (step 5)

| Repo file | Studio object | Type |
|-----------|---------------|------|
| [DodgeballConfig.lua](DodgeballConfig.lua) | `DodgeballConfig` | ModuleScript (paste over step 4 copy) |
| [DodgeballService.server.lua](DodgeballService.server.lua) | `DodgeballService` | Script (paste over step 4 copy) |
| [RoundService.server.lua](RoundService.server.lua) | `RoundService` | Script (new) |

Walkthrough: **[05-round-reset](../05-round-reset/README.md)**.

| Repo file | Studio object | Type |
|-----------|---------------|------|
| [RoundStatusClient.local.lua](RoundStatusClient.local.lua) | `RoundStatusClient` under **StarterGui/RoundStatus** | **LocalScript** |

Optional UI works for step 5 and step 6.

---

## Lobby + matches (step 6)

| Repo file | Studio object | Type |
|-----------|---------------|------|
| [TeamAutoBalance.server.lua](TeamAutoBalance.server.lua) | `TeamAutoBalance` | Script (paste over step 3 copy — lobby-aware teams) |
| [DodgeballConfig.lua](DodgeballConfig.lua) | `DodgeballConfig` | ModuleScript (paste over step 5 copy) |
| [DodgeballService.server.lua](DodgeballService.server.lua) | `DodgeballService` | Script (paste over step 5 copy) |
| [RoundService.server.lua](RoundService.server.lua) | `RoundService` | Script (paste over step 5 copy) |
| [LobbyService.server.lua](LobbyService.server.lua) | `LobbyService` | Script (**new**) |
| [LobbyJoinNextMatchClient.local.lua](LobbyJoinNextMatchClient.local.lua) | `LobbyJoinNextMatchClient` under **StarterPlayerScripts** | **LocalScript** |

Walkthrough: **[06-lobby-and-matches](../06-lobby-and-matches/README.md)** (lobby **SpawnLocation** + refresh **RoundStatusClient** if you added UI in step 5 + optional **LobbyJoinNextMatchClient** opt-in button).