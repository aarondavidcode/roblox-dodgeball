# Roblox dodgeball — START HERE

**The game lives in Roblox.** Your arena, teams, and scripts all live inside **Roblox Studio** on your family’s place.

**The instructions live here.** This repo is a kid-friendly guide plus copy-paste scripts. Nothing in GitHub *is* the game until you build and publish it in Studio.

## 30-second overview

You are making a **Red vs Blue dodgeball** map:

1. **Build** your arena in Studio (walls, sides, fun decorations).
2. **Set up** teams, spawn pads, and the main windows.
3. **Add** the **TeamAutoBalance** server script so new players join the smaller team.
4. **Add dodgeballs** — pickup, throw, and OUT rules (**DodgeballService**).
5. **Round reset** — when a team wins, countdown and respawn (**RoundService**).
6. **Lobby + matches** — lobby countdown, **Join next match** button, first team to **3** round wins (**LobbyService**).
7. **Test** with **F5**, then **2 Players**, then publish with a parent when you are ready.

## Start with step 1

Go to **[01-build-your-map](01-build-your-map/README.md)** and follow the folders in order (`01` → `02` → `03`).

| Folder | What you do |
|--------|-------------|
| [01-build-your-map](01-build-your-map/README.md) | Design the arena and spawn zones |
| [02-studio-setup](02-studio-setup/README.md) | Teams, spawns, Studio panels |
| [03-add-your-first-script](03-add-your-first-script/README.md) | Paste **TeamAutoBalance** from [scripts/](scripts/) |
| [04-balls-and-throwing](04-balls-and-throwing/README.md) | Balls in **Workspace**, **DodgeballService**, throw with **F** or click |
| [05-round-reset](05-round-reset/README.md) | **RoundService**, win detection, ball respawn, optional countdown UI |
| [06-lobby-and-matches](06-lobby-and-matches/README.md) | **LobbyService**, lobby spawn, opt-in UI, first-to-3 matches |

Parents: read **[FOR-PARENTS.md](FOR-PARENTS.md)**. Roadmap: **[WHATS-NEXT.md](WHATS-NEXT.md)**.

## Publish reminder (with a grown-up)

When your place works in Studio, a parent can use **File → Publish to Roblox**. Keep the experience **Private** until your family is ready to invite friends. Publishing does **not** happen from this GitHub repo—it only happens inside Studio.

Have fun building—the code catches up with your creativity.