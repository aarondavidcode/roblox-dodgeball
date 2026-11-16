# Step 6 — Lobby, countdown, and first-to-3 matches

You already have dodgeballs, OUT rules, and **round** wins. This step adds a **lobby** (waiting room), a **Join next match** button so players choose who plays, a **countdown** when **2 or more** players are joining the next match, and **matches**: the first team to win **3 rounds** wins the whole match—then everyone goes back to the lobby.

**Before you start:** Finish **[05-round-reset](../05-round-reset/README.md)**.

---

## What you are adding

| Thing in Studio | Exact name | Where it lives |
|-----------------|------------|----------------|
| Fresh numbers | `DodgeballConfig` | **ServerScriptService** (paste full file) |
| OUT + lobby rules | `DodgeballService` | **ServerScriptService** (paste full file) |
| Match-aware rounds | `RoundService` | **ServerScriptService** (paste full file) |
| Lobby + match flow | `LobbyService` | **ServerScriptService** (Script, **new**) |
| **Your** lobby pad | `LobbySpawn` (or your name from config) | **Workspace** — **you** choose where |
| Countdown text (optional) | `RoundStatus` | **StarterGui** (from step 5 — paste fresh **RoundStatusClient**) |
| Join / spectate button | `LobbyJoinNextMatchClient` | **StarterPlayerScripts** (**LocalScript**) — builds **JoinNextMatch** ScreenGui at run time |

Repo files to copy:

- [DodgeballConfig.lua](../scripts/DodgeballConfig.lua)
- [DodgeballService.server.lua](../scripts/DodgeballService.server.lua)
- [RoundService.server.lua](../scripts/RoundService.server.lua)
- [LobbyService.server.lua](../scripts/LobbyService.server.lua) — **new**
- [TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua) — **updated** (lobby = Neutral, no team)
- [LobbyJoinNextMatchClient.local.lua](../scripts/LobbyJoinNextMatchClient.local.lua) — **new** (lobby opt-in button)
- [RoundStatusClient.local.lua](../scripts/RoundStatusClient.local.lua) — **updated** (opted-in count in lobby text)

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
| `JOIN_NEXT_MATCH_ATTR` | Player flag for joining (default name **`JoinNextMatch`**) |
| `SET_JOIN_NEXT_MATCH_REMOTE_NAME` | Remote for the button (default **`SetJoinNextMatch`**) |

---

## Step 3 — Update DodgeballService (OUT = die, not freeze)

1. Replace **DodgeballService** with the new repo file.

**What it does with the lobby:**

- Getting hit **kills** your character for that round.
- You **do not** respawn until **RoundService** starts the next round (or a new match).
- `IsOut` stays **true** so the round still ends correctly.
- Arena spawns face the other team when team pads match **[step 2](../02-studio-setup/README.md)**.

---

## Step 4 — Update RoundService

1. Replace **RoundService** with the new repo file.

**What it does with the lobby:**

- Rounds run only when **`MatchPhase`** is **`InMatch`** (**LobbyService** sets that).
- A round win gives that team **+1 match point**.
- Between rounds, players respawn on **team** spawns (same idea as step 5).
- When a team hits **3** match points, **LobbyService** sends everyone to the lobby.

---

## Step 5 — Update TeamAutoBalance (lobby-safe teams)

1. Replace **TeamAutoBalance** with **[scripts/TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua)**.

**What it does with the lobby:**

- In **lobby**, players stay **Neutral** with **no** Red/Blue team.
- **Red/Blue** assignment happens when the lobby countdown ends—only for players on **Joining next match**.

## Step 6 — Add LobbyService

1. Under **ServerScriptService**, insert a **Script**.
2. Rename it **`LobbyService`**.
3. Paste from **[scripts/LobbyService.server.lua](../scripts/LobbyService.server.lua)**.

You should have **four** game scripts: **TeamAutoBalance**, **DodgeballService**, **RoundService**, **LobbyService**.

---

## Step 7 — Add the join / spectate button (LobbyJoinNextMatchClient)

In the lobby, each player picks whether they want the **next** match. Everyone starts as **Joining next match**. Tap the button to switch to **Spectating** if you want to watch instead.

1. Under **StarterPlayer**, open **StarterPlayerScripts**.
2. Insert a **LocalScript**.
3. Rename it **`LobbyJoinNextMatchClient`**.
4. Paste from **[scripts/LobbyJoinNextMatchClient.local.lua](../scripts/LobbyJoinNextMatchClient.local.lua)**.

While you play (**F5**), the script builds **PlayerGui → JoinNextMatch → BottomBar**:

| UI piece | What it does |
|----------|----------------|
| **`OptInToggle`** | Green **Joining next match** or blue **Spectating** — tap to switch |
| **`QueueHint`** | One-time tip: *Tap here to queue or spectate* (fades away) |

**Who sees the bar**

| Situation | Bar visible? |
|-----------|----------------|
| **Lobby**, Neutral, no team | Yes |
| **InMatch** and you’re playing | No |
| **InMatch** spectator on the lobby pad | Yes — chooses the **next** match, not this one |

**Kid-simple server rules**

- The first time you join the server, you count as **joining** unless you tap **Spectating**.
- The lobby timer starts when **at least 2** players are **joining**—not when 2 people are merely standing in the lobby.
- When the timer ends, only **joining** players get Red/Blue and go to the arena. **Spectating** players stay on **LobbySpawn** and cannot throw until they join a later match.
- If you chose **Spectating**, that choice sticks until you tap **Joining next match** again (or leave and come back).

**LobbyService** creates the **`SetJoinNextMatch`** remote under **`ReplicatedStorage/DodgeballRemotes`** when you paste the latest **LobbyService** script.

---

## Joining during a match (late joiners)

If someone joins while a match is already running:

- They land on the **lobby** pad as **Neutral** (`MatchParticipant` **false**).
- They cannot throw or join mid-round.
- They can use the **Joining next match** button to queue for the **next** lobby countdown.

---

## Step 8 — How it plays

1. **Lobby** — Everyone spawns at your **lobby** pad. **Output** says `[LobbyService] Lobby phase`.
2. **Join or spectate** — Tap the bottom button if you want **Spectating**; otherwise stay on **Joining next match** (default).
3. **Countdown** — When **2+** players are joining, a **30** s timer runs (change in **DodgeballConfig**).
4. **Not enough joiners** — Timer pauses until **2+** tap **Joining next match**.
5. **Match start** — Timer hits 0 → **InMatch** → joiners go to Red/Blue spawns → **Round 1**; spectators stay on the lobby pad.
6. **Round win** — Same as **[step 5](../05-round-reset/README.md)** (one team all OUT) → **+1 match point**.
7. **Match win** — First team to **3** points → everyone back to lobby, scores reset, new countdown.

---

## Step 9 — Status for UI (ReplicatedStorage)

**LobbyService** and **RoundService** write to **`ReplicatedStorage/RoundStatus`** (same folder as step 5):

| Attribute | Meaning |
|-----------|---------|
| `MatchPhase` | `"Lobby"` or `"InMatch"` |
| `MatchScore_Red` | Red’s match points (names match **TEAM_NAMES**) |
| `MatchScore_Blue` | Blue’s match points |
| `MatchPointsToWin` | Usually **3** |
| `LobbyCountdownEndsAt` | Server time when lobby countdown ends (nil if paused) |
| `LobbyOptedInCount` | Players with **`JoinNextMatch` true** (updates during lobby and **InMatch**; used when the next lobby countdown starts) |
| `RoundState` | `LobbyIdle`, `Playing`, `Intermission`, `Resetting` |
| `RoundNumber` | Current arena round in the match |
| `IntermissionEndsAt` | Between-round countdown (step 5) |

---

## Step 10 — RoundStatus countdown text

If you built **`RoundStatus`** in step 5, **replace** the **RoundStatusClient** LocalScript with **[scripts/RoundStatusClient.local.lua](../scripts/RoundStatusClient.local.lua)**. Setup steps: **[05-round-reset — Step 5](../05-round-reset/README.md#step-5--optional-roundstatus-ui-countdown-text)**.

**Lobby examples** (top of screen):

| Situation | Example text |
|-----------|----------------|
| Only 1 player in server | `Lobby — waiting for another player…` |
| 2+ players but fewer than 2 joining | `Lobby — 1 joined next match (need 2)…` |
| Countdown running | `Lobby — match starts in 24s (2 playing)` |
| Joiners needed | `Lobby — tap Play next match to join (1/2+)…` |

The last line is a nudge when the countdown is paused—use the **`OptInToggle`** button (**Joining next match** / **Spectating**), not a separate “Play” control.

---

## Step 11 — Test with F5

### Two players (basic)

1. **Save** the place.
2. **F5** (Play). **View → Output** — look for `[LobbyService]` and `[RoundService] Waiting for lobby match start`.
3. **Test → 2 Players**.
4. Confirm the lobby countdown **starts on its own** with two players (both default opted in).
5. When the match starts, play until one team wins **3 rounds** (you can lower `MATCH_POINTS_TO_WIN` in config for a quick test).
6. Confirm OUT players **die** and stay out until the round resets.
7. After match win, both players should return to **lobby** and scores reset.

### Three players (opt-in + spectator)

1. **Test → 3 Players**.
2. **Player C**: tap the button until it says **Spectating**. **Players A & B** stay **Joining next match**.
3. Confirm countdown runs; when it hits **0**, **A** and **B** spawn on arena pads; **C** stays on **LobbySpawn** and cannot throw.
4. Let the match finish → all return to lobby → **C** is still **Spectating** until they tap **Joining next match**.

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
  DodgeballRemotes/                   ← SetJoinNextMatch RemoteEvent
  RoundStatus/                        ← MatchPhase, scores, round state
StarterPlayer
  StarterPlayerScripts/
    DodgeballThrowInput
    LobbyJoinNextMatchClient          ← builds JoinNextMatch UI
Workspace
  LobbySpawn                          ← your SpawnLocation (name or tag)
  Red spawn / Blue spawn              ← from step 2
  Dodgeballs/
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Countdown never starts | Need **2+** players on **Joining next match** on two clients; check Output for pause message |
| Everyone in lobby but timer paused | At least **2** must tap **Joining next match** — **Spectating** alone does not start the timer |
| No join button | Paste **LobbyJoinNextMatchClient** under **StarterPlayerScripts**; **LobbyService** must run |
| Stuck at lobby spawn after countdown | Team pads can be named anything (e.g. **RedSpawn** / **BlueSpawn**). Each must have **Neutral off** and **TeamColor** matching **Teams → Red** or **Teams → Blue** — not the pad name. **LobbySpawn** must have **Neutral on**. Re-paste **LobbyService** and watch Output for the TeamColor hint. |
| Wrong lobby spot | Fix **Name** or **Tag** vs **DodgeballConfig** |
| Rounds start immediately | Paste new **LobbyService** + **RoundService**; delete old duplicates |
| Neutral name but Blue spawn | Re-paste **TeamAutoBalance** + **LobbyService** (lobby clears `Team`) |
| Solo player in arena / no lobby | Same — old TeamAutoBalance assigned Red/Blue on join |
| OUT player walks around | Re-paste **DodgeballService** (OUT should kill, not freeze) |
| Match score stuck | Watch **RoundStatus** attributes while a round ends |
| Round winner at **LobbySpawn** next round | Re-paste **LobbyService** + **RoundService** — between-round respawn must call team pad teleport, not **LoadCharacter** alone |
| New player pulled into mid-match arena | Re-paste **LobbyService** + **TeamAutoBalance** — mid-match joiners should stay on **lobby** pad until the match ends |

---

## What is next?

See **[WHATS-NEXT.md](../WHATS-NEXT.md)** for special throws and spectator zones.

Back: **[README.md](../README.md)**.