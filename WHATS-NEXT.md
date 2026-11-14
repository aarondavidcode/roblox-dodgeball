# What’s next

You have enough to **test in Studio** and land on the correct side of **your** map:

- [02-studio-setup](02-studio-setup/README.md) — teams and spawns  
- [03-add-your-first-script](03-add-your-first-script/README.md) — **TeamAutoBalance**  
- [scripts/TeamAutoBalance.server.lua](scripts/TeamAutoBalance.server.lua)

---

## Roadmap: scripts to add later

Short list of what comes next (not all written in this repo yet):

- **Dodgeball tool** — Give each player a ball (Tool in StarterPack or server equips), throw force, cooldown so spam is fair.
- **Out-of-bounds / hit rules** — When a ball touches an opponent, mark them “out” (humanoid health, tag attribute, or sit-out zone)—agree one rule set for your family.
- **Round reset** — When one team wins, teleport everyone back, clear outs, respawn balls, optional countdown UI.
- **Lobby vs arena** — Neutral spawn between rounds (optional **Neutral** SpawnLocation), then team spawns when round starts—like many official team tutorials.

Kids keep iterating the **map** (cover, boundaries, spectator spots); each bullet above is a **small script milestone** you can add one at a time.

When a new script lands in this repo, read its guide, open the `.lua` file on GitHub, copy into Studio, and test again—your models stay put.

---

## How to use this repo with Studio

1. Set up the place once with [02-studio-setup](02-studio-setup/README.md).  
2. Paste scripts from **[scripts/](scripts/)** when a guide tells you to.  
3. Test with **F5** and **2 Players** before inviting friends.  
4. Watch this repo for updates; copy fresh script text when guides change.

Back to the start: **[README.md](README.md)**.