# Step 6 — Lobby, countdown, and first-to-3 matches

You already have dodgeballs, OUT rules, and **round** wins. This step adds a **lobby** (waiting room), a **countdown** when 2+ players are ready, and a **match**: the first team to win **3 rounds** wins the whole match—then everyone goes back to the lobby.

**Before you start:** Finish **[05-round-reset](../05-round-reset/README.md)**.

---

## What you are adding

| Thing in Studio | Exact name | Where it lives |
|-----------------|------------|----------------|
| Updated numbers | `DodgeballConfig` | **ServerScriptService** (paste fresh copy) |
| Updated OUT = death | `DodgeballService` | **ServerScriptService** (paste fresh copy) |
| Updated rounds | `RoundService` | **ServerScriptService** (paste fresh copy) |
| Lobby + match flow | `LobbyService` | **ServerScriptService** (Script, **new**) |
| **Your** lobby pad | `LobbySpawn` (or your name from config) | **Workspace** — **you** choose where |
| Optional UI | `RoundStatus` | **StarterGui** (same UI as step 5 — paste updated **RoundStatusClient**) |

Repo files to copy:

- [DodgeballConfig.lua](../scripts/DodgeballConfig.lua)
- [DodgeballService.server.lua](../scripts/DodgeballService.server.lua)
- [RoundService.server.lua](../scripts/RoundService.server.lua)
- [LobbyService.server.lua](../scripts/LobbyService.server.lua) — **new**
- [TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua) — **updated** (lobby = Neutral, no team)

Leave **throw/DefaultThrow** and **DodgeballThrowInput** as they are.

---

## Step 1 — Wire a lobby spawn (kids choose the spot)

The code does **not** tell you where to build. You only **wire** a spawn the scripts can find.

**Option A — name (default)**

1. In **Workspace**, insert or pick a **SpawnLocation** where you want the lobby (anywhere on your map).
2. Rename it to **`LobbySpawn`** (must match `LOBBY_SPAWN_NAME` in **DodgeballConfig**).
3. In **Properties** for that pad:
   - Set **TeamColor** to **Neutral** (or a neutral brick color).
   - Turn **AllowTeamChangeOnTouch** **off** if you do not want team switching on that pad.

**Option B — tag**

1. Pick your lobby **SpawnLocation** (any name).
2. **View → Tag Editor** → add tag **`LobbySpawn`** (or change `LOBBY_SPAWN_TAG` in config to match your tag).

Team arena spawns from **[02-studio-setup](../02-studio-setup/README.md)** stay **Red** / **Blue**. Only the lobby pad is neutral.

---

## Step 2 — Update DodgeballConfig

1. Select **DodgeballConfig** in **ServerScriptService**.
2. Replace all code with **[scripts/DodgeballConfig.lua](../scripts/DodgeballConfig.lua)**.

New settings at the bottom:

| Setting | Kid meaning |
|---------|-------------|
| `LOBBY_COUNTDOWN_SECONDS` | Wait time in lobby when 2+ players (default **30**) |
| `MATCH_POINTS_TO_WIN` | Round wins needed to win the **match** (default **3**) |
| `LOBBY_SPAWN_NAME` | Name of your lobby **SpawnLocation** |
| `LOBBY_SPAWN_TAG` | Optional tag instead of name (empty = use name only) |

---

## Step 3 — Update DodgeballService (OUT = die, not freeze)

1. Replace **DodgeballService** with the new repo file.

**What changed:**

- Getting hit **kills** your character for that round (`Humanoid.Health = 0`).
- You **do not** respawn until **RoundService** starts the next round (or a new match).
- `IsOut` stays **true** so the round still ends correctly.
- No more **WalkSpeed = 0** freeze.

---

## Step 4 — Update RoundService

1. Replace **RoundService** with the new repo file.

**What changed:**

- Rounds run only when **`MatchPhase`** is **`InMatch`** (set by **LobbyService**).
- A round win can award a **match point** (see **LobbyService**).
- If the match is not over, players respawn on **team** spawns like step 5.
- If the match **is** over (3 points), **LobbyService** sends everyone to the lobby (no extra arena respawn).

---

## Step 5 — Update TeamAutoBalance (lobby-safe teams)

1. Replace **TeamAutoBalance** with **[scripts/TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua)**.

**What changed:**

- In **lobby**, players stay **Neutral** with **no** Red/Blue team (fixes wrong arena spawn while waiting).
- **Red/Blue** assignment happens when the lobby countdown ends and a match starts (and when someone joins mid-match).

## Step 6 — Add LobbyService

1. Under **ServerScriptService**, insert a **Script**.
2. Rename it **`LobbyService`**.
3. Paste from **[scripts/LobbyService.server.lua](../scripts/LobbyService.server.lua)**.

You should have **four** game scripts: **TeamAutoBalance**, **DodgeballService**, **RoundService**, **LobbyService**.

---

## Step 7 — How it plays

1. **Lobby** — Everyone spawns at your **lobby** pad. **Output** says `[LobbyService] Lobby phase`.
2. **Countdown** — With **2 or more** players, a **30** second lobby timer runs (change in config).
3. **One player left** — Timer **pauses** and resets to full **30** until 2+ are back.
4. **Match start** — Timer hits 0 → **`InMatch`** → players load on **Red/Blue** spawns → **Round 1**.
5. **Round win** — Same as step 5 (one team all OUT) → **+1 match point** for that team.
6. **Match win** — First team to **3** match points → back to **lobby**, scores **0**, countdown again.

---

## Step 8 — Status for UI (ReplicatedStorage)

**LobbyService** and **RoundService** write to **`ReplicatedStorage/RoundStatus`** (same folder as step 5):

| Attribute | Meaning |
|-----------|---------|
| `MatchPhase` | `"Lobby"` or `"InMatch"` |
| `MatchScore_Red` | Red’s match points (names match **TEAM_NAMES**) |
| `MatchScore_Blue` | Blue’s match points |
| `MatchPointsToWin` | Usually **3** |
| `LobbyCountdownEndsAt` | Server time when lobby countdown ends (nil if paused) |
| `RoundState` | `LobbyIdle`, `Playing`, `Intermission`, `Resetting` |
| `RoundNumber` | Current arena round in the match |
| `IntermissionEndsAt` | Between-round countdown (step 5) |

---

## Step 9 — Optional RoundStatus UI

Use the **same** ScreenGui as **[05-round-reset — Step 5](../05-round-reset/README.md#step-5--optional-roundstatus-ui-countdown-text)** (`RoundStatus` / `CountdownLabel` / `RoundStatusClient` LocalScript).

If you already pasted the old step 5 script, **replace** it with the latest **[scripts/RoundStatusClient.local.lua](../scripts/RoundStatusClient.local.lua)** so lobby countdown shows instead of `Round N — PLAY!` while `MatchPhase` is **Lobby**.

**Checklist**

- ScreenGui named **`RoundStatus`** (not `MatchStatus`).
- TextLabel named **`CountdownLabel`**; **Text** property empty.
- Child script is **`RoundStatusClient`**, class **LocalScript**, code from the repo file above.

---

## Step 10 — Test with F5 and 2 Players

1. **Save** the place.
2. **F5** (Play). **View → Output** — look for `[LobbyService]` and `[RoundService] Waiting for lobby match start`.
3. **Test → 2 Players**.
4. Stand on lobby spawn; watch lobby countdown in Output or UI.
5. When the match starts, play until one team wins **3 rounds** (you can lower `MATCH_POINTS_TO_WIN` in config for a quick test).
6. Confirm OUT players **die** and stay out until the round resets.
7. After match win, both players should return to **lobby** and scores reset.

**Stop** when done.

---

## Studio layout cheat sheet

```
ServerScriptService
  TeamAutoBalance
  DodgeballConfig
  DodgeballService
  RoundService
  LobbyService                      ← new
  DodgeballRoundBridge/             ← auto
  throw/
    DefaultThrow
ReplicatedStorage
  DodgeballRemotes/
  RoundStatus/                        ← MatchPhase, scores, round state
Workspace
  LobbySpawn                          ← your SpawnLocation (name or tag)
  Red spawn / Blue spawn              ← from step 2
  Dodgeballs/
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Countdown never starts | Need **2** players; check Output for pause message |
| Stuck in lobby after countdown | Team **SpawnLocations** must match **Red** / **Blue** colors (step 2) |
| Wrong lobby spot | Fix **Name** or **Tag** vs **DodgeballConfig** |
| Rounds start immediately | Paste new **LobbyService** + **RoundService**; delete old duplicates |
| Neutral name but Blue spawn | Re-paste **TeamAutoBalance** + **LobbyService** (lobby clears `Team`) |
| Solo player in arena / no lobby | Same — old TeamAutoBalance assigned Red/Blue on join |
| OUT player walks around | Re-paste **DodgeballService** (OUT should kill, not freeze) |
| Match score stuck | Watch **RoundStatus** attributes while a round ends |

---

## What is next?

See **[WHATS-NEXT.md](../WHATS-NEXT.md)** for special throws and spectator zones.

Back: **[README.md](../README.md)**.