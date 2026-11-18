# Scripts

Luau sources to paste into **Roblox Studio**. Each script has a folder here with its `.lua` file(s) and colocated setup markdown.

**Start here:** [README.md](../README.md) (scripts table and paste steps). **Rojo sync:** [docs/rojo-studio-sync.md](../docs/rojo-studio-sync.md) + [default.project.json](../default.project.json).

## Repo layout vs Studio

| GitHub (this repo) | Roblox Studio (your place) |
|--------------------|----------------------------|
| `scripts/DodgeballConfig/DodgeballConfig.lua` | `ServerScriptService/DodgeballConfig` ModuleScript |
| `scripts/throw/DefaultThrow/DefaultThrow.lua` | `ServerScriptService/throw/DefaultThrow` ModuleScript |
| `scripts/DodgeballService/DodgeballService.server.lua` | `ServerScriptService/DodgeballService` Script |

Explorer **instance names** must match the root README table. `require()` in Luau uses those names (e.g. `require(ServerScriptService.DodgeballConfig)`, folder `throw` + module `DefaultThrow`) — not GitHub folder paths.

## Index

| Folder | Doc |
|--------|-----|
| [DodgeballConfig/](DodgeballConfig/DodgeballConfig.md) | [DodgeballConfig.md](DodgeballConfig/DodgeballConfig.md) |
| [DodgeballBallTemplate/](DodgeballBallTemplate/DodgeballBallTemplate.md) | [DodgeballBallTemplate.md](DodgeballBallTemplate/DodgeballBallTemplate.md) |
| [DodgeballThrowerCollision/](DodgeballThrowerCollision/DodgeballThrowerCollision.md) | [DodgeballThrowerCollision.md](DodgeballThrowerCollision/DodgeballThrowerCollision.md) |
| [TeamAutoBalance/](TeamAutoBalance/TeamAutoBalance.md) | [TeamAutoBalance.md](TeamAutoBalance/TeamAutoBalance.md) |
| [DodgeballService/](DodgeballService/DodgeballService.md) | [DodgeballService.md](DodgeballService/DodgeballService.md) |
| [throw/DefaultThrow/](throw/DefaultThrow/DefaultThrow.md) | [DefaultThrow.md](throw/DefaultThrow/DefaultThrow.md) |
| [DodgeballThrowInput/](DodgeballThrowInput/DodgeballThrowInput.md) | [DodgeballThrowInput.md](DodgeballThrowInput/DodgeballThrowInput.md) |
| [RoundService/](RoundService/RoundService.md) | [RoundService.md](RoundService/RoundService.md) |
| [RoundStatusClient/](RoundStatusClient/RoundStatusClient.md) | [RoundStatusClient.md](RoundStatusClient/RoundStatusClient.md) |
| [LobbyService/](LobbyService/LobbyService.md) | [LobbyService.md](LobbyService/LobbyService.md) |
| [LobbyPracticeBallService/](LobbyPracticeBallService/LobbyPracticeBallService.md) | [LobbyPracticeBallService.md](LobbyPracticeBallService/LobbyPracticeBallService.md) |
| [LobbyJoinNextMatchClient/](LobbyJoinNextMatchClient/LobbyJoinNextMatchClient.md) | [LobbyJoinNextMatchClient.md](LobbyJoinNextMatchClient/LobbyJoinNextMatchClient.md) |
| [ball-physics/](ball-physics/README.md) | Vendored **BallPhysics** v1.0.0 → `ReplicatedStorage/BallPhysics` **ModuleScript** tree |
| [BallPhysicsAutoSetup/](BallPhysicsAutoSetup/BallPhysicsAutoSetup.md) | [BallPhysicsAutoSetup.md](BallPhysicsAutoSetup/BallPhysicsAutoSetup.md) |
| [BallPhysicsClient/](BallPhysicsClient/BallPhysicsClient.md) | [BallPhysicsClient.md](BallPhysicsClient/BallPhysicsClient.md) |
| [DodgeballBallPhysicsDebug/](DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md) | [DodgeballBallPhysicsDebug.md](DodgeballBallPhysicsDebug/DodgeballBallPhysicsDebug.md) |
| [DodgeballMatchNpc/](DodgeballMatchNpc/DodgeballMatchNpc.md) | [DodgeballMatchNpc.md](DodgeballMatchNpc/DodgeballMatchNpc.md) |
| [DodgeballSinglePlayerTest/](DodgeballSinglePlayerTest/DodgeballSinglePlayerTest.md) | [DodgeballSinglePlayerTest.md](DodgeballSinglePlayerTest/DodgeballSinglePlayerTest.md) |