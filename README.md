# Roblox dodgeball

Red vs Blue dodgeball for **Roblox Studio**. This repo holds Luau you paste into a place plus markdown that says where each script lives in Explorer and what you must build by hand in the 3D world.

The playable game is always your **Roblox place** (arena, teams, spawns). GitHub is the script source and setup reference.

## Game systems (short map)

| System | Server scripts | Client scripts | Shared config |
|--------|----------------|----------------|---------------|
| Teams | `TeamAutoBalance`, `LobbyService` | — | `DodgeballConfig` |
| Lobby and matches | `LobbyService`, `LobbyPracticeBallService` | `LobbyJoinNextMatchClient` | `DodgeballConfig` |
| Dodgeballs | `DodgeballService` | `DodgeballThrowInput` | `DodgeballConfig`, `throw/DefaultThrow` |
| Rounds | `RoundService` | `RoundStatusClient` (optional UI) | `DodgeballConfig` |

**Typical flow:** Players wait on a **lobby spawn** → opt in to the next match → countdown → Red/Blue on arena pads → rounds until one team is all OUT → first to **3** round wins wins the match → back to lobby.

**Test in Studio:** **F5** for one player, **Test → 2 Players** (or more) for teams and lobby logic. Watch **View → Output** for `[TeamAutoBalance]`, `[LobbyService]`, `[DodgeballService]`, `[RoundService]`.

## Scripts → Studio location → doc

Copy from [scripts/](scripts/) on GitHub (**Raw** or select all). Object **names** in Explorer must match the table.

| Repo file | Explorer path | Instance type | Doc |
|-----------|---------------|---------------|-----|
| [DodgeballConfig.lua](scripts/DodgeballConfig.lua) | `ServerScriptService/DodgeballConfig` | ModuleScript | [docs/DodgeballConfig.md](docs/DodgeballConfig.md) |
| [TeamAutoBalance.server.lua](scripts/TeamAutoBalance.server.lua) | `ServerScriptService/TeamAutoBalance` | Script | [docs/TeamAutoBalance.md](docs/TeamAutoBalance.md) |
| [DodgeballService.server.lua](scripts/DodgeballService.server.lua) | `ServerScriptService/DodgeballService` | Script | [docs/DodgeballService.md](docs/DodgeballService.md) |
| [throw/DefaultThrow.lua](scripts/throw/DefaultThrow.lua) | `ServerScriptService/throw/DefaultThrow` | ModuleScript | [docs/DefaultThrow.md](docs/DefaultThrow.md) |
| [DodgeballThrowInput.local.lua](scripts/DodgeballThrowInput.local.lua) | `StarterPlayer/StarterPlayerScripts/DodgeballThrowInput` | LocalScript | [docs/DodgeballThrowInput.md](docs/DodgeballThrowInput.md) |
| [RoundService.server.lua](scripts/RoundService.server.lua) | `ServerScriptService/RoundService` | Script | [docs/RoundService.md](docs/RoundService.md) |
| [RoundStatusClient.local.lua](scripts/RoundStatusClient.local.lua) | `StarterGui/RoundStatus/RoundStatusClient` | LocalScript | [docs/RoundStatusClient.md](docs/RoundStatusClient.md) |
| [LobbyService.server.lua](scripts/LobbyService.server.lua) | `ServerScriptService/LobbyService` | Script | [docs/LobbyService.md](docs/LobbyService.md) |
| [LobbyPracticeBallService.server.lua](scripts/LobbyPracticeBallService.server.lua) | `ServerScriptService/LobbyPracticeBallService` | Script | [docs/LobbyPracticeBallService.md](docs/LobbyPracticeBallService.md) |
| [LobbyJoinNextMatchClient.local.lua](scripts/LobbyJoinNextMatchClient.local.lua) | `StarterPlayer/StarterPlayerScripts/LobbyJoinNextMatchClient` | LocalScript | [docs/LobbyJoinNextMatchClient.md](docs/LobbyJoinNextMatchClient.md) |

**Place setup you build (not in repo):** arena in `Workspace`, **Teams** named `Red` and `Blue`, team **SpawnLocations** with matching **TeamColor** and **Neutral** off, lobby **SpawnLocation** (**Neutral** on), folder `Workspace/Dodgeballs` with ball Parts, lobby practice **spawn volumes** tagged `LobbyBallSpawnVolume` (optional exclude zones). Details live in the script docs above.

## Paste or update one script

1. Open the **.lua** file in this repo and copy the full source.
2. In Studio **Explorer**, select the matching object (or create it with the right type and name — see that script’s doc).
3. Open the script editor, replace all code, **Save** the place.
4. If Studio human setup changed (new spawn name, new UI child), update **only** that script’s markdown in `docs/`.

Do not paste duplicates of **ModuleScripts** or server **Scripts** with different names. Do not hand-create `ReplicatedStorage/DodgeballRemotes`, `RoundStatus`, or `ServerScriptService/DodgeballRoundBridge` — scripts create those at run time.

## Publish

**File → Publish to Roblox** happens in Studio, not from GitHub. Set the experience visibility in [create.roblox.com](https://create.roblox.com) before inviting players.

## Cloud agents

Saved environment: [`.cursor/environment.json`](.cursor/environment.json). Agent notes: [`.cursor/AGENTS.md`](.cursor/AGENTS.md). [Cloud Agents dashboard](https://cursor.com/dashboard?tab=cloud-agents).