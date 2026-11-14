# What’s next

You have enough to **test in Studio** and land on the correct side of **your** map:

- [02-studio-setup](02-studio-setup/README.md) — teams and spawns  
- [03-add-your-first-script](03-add-your-first-script/README.md) — **TeamAutoBalance** ✅  
- [04-balls-and-throwing](04-balls-and-throwing/README.md) — dodgeballs, throw, OUT rules ✅  
- [05-round-reset](05-round-reset/README.md) — rounds, win, respawn ✅  
- [06-lobby-and-matches](06-lobby-and-matches/README.md) — lobby, countdown, first-to-3 matches ✅  
- [scripts/TeamAutoBalance.server.lua](scripts/TeamAutoBalance.server.lua)  
- [scripts/LobbyService.server.lua](scripts/LobbyService.server.lua)  
- [scripts/RoundService.server.lua](scripts/RoundService.server.lua)  
- [scripts/DodgeballService.server.lua](scripts/DodgeballService.server.lua)  
- [scripts/DodgeballConfig.lua](scripts/DodgeballConfig.lua)  
- [scripts/throw/DefaultThrow.lua](scripts/throw/DefaultThrow.lua)

---

## Roadmap: scripts to add later

Short list of what comes next:

- **Special throws** — New modules under `ServerScriptService/throw/` and set **ACTIVE_THROW_PROFILE** in **DodgeballConfig** (curveball, fastball, etc.).
- **Spectator / sit-out zone** — Sideline camera or teleport for players who are OUT for the round (they already **die** instead of freezing).

Kids keep iterating the **map** (cover, boundaries, spectator spots); each bullet above is a **small script milestone** you can add one at a time.

When a new script lands in this repo, read its guide, open the `.lua` file on GitHub, copy into Studio, and test again—your models stay put.

---

## How to use this repo with Studio

1. Set up the place once with [02-studio-setup](02-studio-setup/README.md).  
2. Paste scripts from **[scripts/](scripts/)** when a guide tells you to.  
3. Test with **F5** and **2 Players** before inviting friends.  
4. Watch this repo for updates; copy fresh script text when guides change.

Back to the start: **[README.md](README.md)**.