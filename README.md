# Roblox dodgeball

Red vs Blue dodgeball for **Roblox Studio**. This repo holds Luau you paste into a place plus markdown beside each script for Explorer paths and what you build in the 3D world.

The playable game is always your **Roblox place** (arena, teams, spawns). GitHub is the script source and setup reference.

**Repo layout:** Each script lives under `scripts/<Name>/` with colocated `<Name>.md`. Studio uses **flat Explorer names** (see table below) — not the GitHub folder paths. Module `require()` uses instance names (`DodgeballConfig`, `throw.DefaultThrow`, etc.).

## Game systems (short map)

| System | Server scripts | Client scripts | Shared config |
|--------|----------------|----------------|---------------|
| Teams | `TeamAutoBalance`, `LobbyService` | — | `DodgeballConfig` |
| Lobby and matches | `LobbyService`, `LobbyPracticeBallService` | `LobbyJoinNextMatchClient` | `DodgeballConfig` |
| Dodgeballs | `DodgeballService`, `DodgeballBallTemplate`, `DodgeballThrowerCollision`, `BallPhysicsAutoSetup` | `DodgeballThrowInput`, `BallPhysicsClient`, `DodgeballBallVisualEffectsClient` | `DodgeballConfig`, `throw/DefaultThrow`, `ReplicatedStorage/BallPhysics` |
| Rounds | `RoundService` | `RoundStatusClient` (optional UI) | `DodgeballConfig` |

**Typical flow:** Players wait on a **lobby spawn** → opt in to the next match → countdown → Red/Blue on arena pads → rounds until one team is all OUT → first to **3** round wins wins the match → back to lobby.

**Test in Studio:** **F5** for one player, **Test → 2 Players** (or more) for teams and lobby logic. Watch **View → Output** for `[TeamAutoBalance]`, `[LobbyService]`, `[DodgeballService]`, `[RoundService]`.

## Scripts → Studio location → doc

Copy from the `.lua` file in each folder under [scripts/](scripts/) on GitHub (**Raw** or select all). Object **names** in Explorer must match the table.

| Repo path | Explorer path | Instance type | Studio setup doc |
|-----------|---------------|---------------|------------------|
| [scripts/DodgeballConfig/DodgeballConfig.lua](scripts/DodgeballConfig/DodgeballConfig.lua) | `ServerScriptService/DodgeballConfig` | ModuleScript | [DodgeballConfig.md](scripts/DodgeballConfig/DodgeballConfig.md) |
| [scripts/DodgeballBallTemplate/DodgeballBallTemplate.lua](scripts/DodgeballBallTemplate/DodgeballBallTemplate.lua) | `ServerScriptService/DodgeballBallTemplate` | ModuleScript | [DodgeballBallTemplate.md](scripts/DodgeballBallTemplate/DodgeballBallTemplate.md) |
| [scripts/DodgeballThrowerCollision/DodgeballThrowerCollision.lua](scripts/DodgeballThrowerCollision/DodgeballThrowerCollision.lua) | `ServerScriptService/DodgeballThrowerCollision` | ModuleScript | [DodgeballThrowerCollision.md](scripts/DodgeballThrowerCollision/DodgeballThrowerCollision.md) |
| [scripts/TeamAutoBalance/TeamAutoBalance.server.lua](scripts/TeamAutoBalance/TeamAutoBalance.server.lua) | `ServerScriptService/TeamAutoBalance` | Script | [TeamAutoBalance.md](scripts/TeamAutoBalance/TeamAutoBalance.md) |
| [scripts/DodgeballService/DodgeballService.server.lua](scripts/DodgeballService/DodgeballService.server.lua) | `ServerScriptService/DodgeballService` | Script | [DodgeballService.md](scripts/DodgeballService/DodgeballService.md) |
| [scripts/throw/DefaultThrow/DefaultThrow.lua](scripts/throw/DefaultThrow/DefaultThrow.lua) | `ServerScriptService/throw/DefaultThrow` | ModuleScript | [DefaultThrow.md](scripts/throw/DefaultThrow/DefaultThrow.md) |
| [scripts/DodgeballThrowInput/DodgeballThrowInput.local.lua](scripts/DodgeballThrowInput/DodgeballThrowInput.local.lua) | `StarterPlayer/StarterPlayerScripts/DodgeballThrowInput` | LocalScript | [DodgeballThrowInput.md](scripts/DodgeballThrowInput/DodgeballThrowInput.md) |
| [scripts/RoundService/RoundService.server.lua](scripts/RoundService/RoundService.server.lua) | `ServerScriptService/RoundService` | Script | [RoundService.md](scripts/RoundService/RoundService.md) |
| [scripts/RoundStatusClient/RoundStatusClient.local.lua](scripts/RoundStatusClient/RoundStatusClient.local.lua) | `StarterGui/RoundStatus/RoundStatusClient` | LocalScript | [RoundStatusClient.md](scripts/RoundStatusClient/RoundStatusClient.md) |
| [scripts/LobbyService/LobbyService.server.lua](scripts/LobbyService/LobbyService.server.lua) | `ServerScriptService/LobbyService` | Script | [LobbyService.md](scripts/LobbyService/LobbyService.md) |
| [scripts/LobbyPracticeBallService/LobbyPracticeBallService.server.lua](scripts/LobbyPracticeBallService/LobbyPracticeBallService.server.lua) | `ServerScriptService/LobbyPracticeBallService` | Script | [LobbyPracticeBallService.md](scripts/LobbyPracticeBallService/LobbyPracticeBallService.md) |
| [scripts/LobbyJoinNextMatchClient/LobbyJoinNextMatchClient.local.lua](scripts/LobbyJoinNextMatchClient/LobbyJoinNextMatchClient.local.lua) | `StarterPlayer/StarterPlayerScripts/LobbyJoinNextMatchClient` | LocalScript | [LobbyJoinNextMatchClient.md](scripts/LobbyJoinNextMatchClient/LobbyJoinNextMatchClient.md) |
| [scripts/ball-physics/src/](scripts/ball-physics/) (v1.0.0) | `ReplicatedStorage/BallPhysics` (**ModuleScript** root + children) | Module tree | [ball-physics/README.md](scripts/ball-physics/README.md) |
| [scripts/BallPhysicsAutoSetup/BallPhysicsAutoSetup.server.lua](scripts/BallPhysicsAutoSetup/BallPhysicsAutoSetup.server.lua) | `ServerScriptService/BallPhysicsAutoSetup` | Script | [BallPhysicsAutoSetup.md](scripts/BallPhysicsAutoSetup/BallPhysicsAutoSetup.md) |
| [scripts/BallPhysicsClient/BallPhysicsClient.local.lua](scripts/BallPhysicsClient/BallPhysicsClient.local.lua) | `StarterPlayer/StarterPlayerScripts/BallPhysicsClient` | LocalScript | [BallPhysicsClient.md](scripts/BallPhysicsClient/BallPhysicsClient.md) |
| [scripts/DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.local.lua](scripts/DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.local.lua) | `StarterPlayer/StarterPlayerScripts/DodgeballBallVisualEffectsClient` | LocalScript | [DodgeballBallVisualEffectsClient.md](scripts/DodgeballBallVisualEffectsClient/DodgeballBallVisualEffectsClient.md) |
| [scripts/ballVisualEffects/BallVisualEffectRegistry/BallVisualEffectRegistry.lua](scripts/ballVisualEffects/BallVisualEffectRegistry/BallVisualEffectRegistry.lua) | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/BallVisualEffectRegistry` | ModuleScript | [BallVisualEffectRegistry.md](scripts/ballVisualEffects/BallVisualEffectRegistry/BallVisualEffectRegistry.md) |
| [scripts/ballVisualEffects/SpeedGlow/SpeedGlow.lua](scripts/ballVisualEffects/SpeedGlow/SpeedGlow.lua) | `StarterPlayer/StarterPlayerScripts/ballVisualEffects/SpeedGlow` | ModuleScript | [SpeedGlow.md](scripts/ballVisualEffects/SpeedGlow/SpeedGlow.md) |

**Third-party:** [thaalish/ball-physics](https://github.com/thaalish/ball-physics) v1.0.0 (MIT) — vendored under `scripts/ball-physics/`.

**Place setup you build (not in repo):** arena in `Workspace`, **Teams** named `Red` and `Blue`, team **SpawnLocations** with matching **TeamColor** and **Neutral** off, lobby **SpawnLocation** (**Neutral** on), folder `Workspace/Dodgeballs` with ball Parts, lobby practice **spawn volumes** tagged `LobbyBallSpawnVolume` (optional exclude zones). Details live in each script’s markdown above.

## Paste or update one script

1. Open the **.lua** file in this repo and copy the full source.
2. In Studio **Explorer**, select the matching object (or create it with the right type and name — see that script’s colocated `.md`).
3. Open the script editor, replace all code, **Save** the place.
4. If Studio human setup changed (new spawn name, new UI child), update **only** that script’s markdown in its `scripts/<Name>/` folder.

Do not paste duplicates of **ModuleScripts** or server **Scripts** with different names. Do not hand-create `ReplicatedStorage/DodgeballRemotes`, `RoundStatus`, or `ServerScriptService/DodgeballRoundBridge` — scripts create those at run time.

## Publish

**File → Publish to Roblox** happens in Studio, not from GitHub. Set the experience visibility in [create.roblox.com](https://create.roblox.com) before inviting players.

## Cloud agents

Saved environment: [`.cursor/environment.json`](.cursor/environment.json). Agent notes: [`.cursor/AGENTS.md`](.cursor/AGENTS.md). [Cloud Agents dashboard](https://cursor.com/dashboard?tab=cloud-agents).