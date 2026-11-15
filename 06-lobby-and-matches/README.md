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
| Next-match opt-in UI | `LobbyJoinNextMatchClient` | **StarterPlayerScripts** (**LocalScript**, **new**) — builds **JoinNextMatch** ScreenGui at run time |

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

---

## Step 3 — Update DodgeballService (OUT = die, not freeze)

1. Replace **DodgeballService** with the new repo file.

**What changed:**

- Getting hit **kills** your character for that round (`Humanoid.Health = 0`).
- You **do not** respawn until **RoundService** starts the next round (or a new match) — no lobby pad, no team pad, no new character while `IsOut` is true.
- `IsOut` stays **true** so the round still ends correctly.
- Match and arena respawns face the **other team’s** spawn pad when pads are wired in step 2.
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
- **Red/Blue** assignment happens when the lobby countdown ends and a match starts only for players already in the lobby.

## Step 6 — Add LobbyService

1. Under **ServerScriptService**, insert a **Script**.
2. Rename it **`LobbyService`**.
3. Paste from **[scripts/LobbyService.server.lua](../scripts/LobbyService.server.lua)**.

You should have **four** game scripts: **TeamAutoBalance**, **DodgeballService**, **RoundService**, **LobbyService**.

---

## Step 6b — Lobby opt-in for the next match (optional UI)

**Neutral** players in the **lobby** choose whether they join the upcoming match. Spectators who stay out of the countdown still hang out on the lobby pad and **cannot** throw until they opt in (or the match ends).

1. Under **StarterPlayer**, open **StarterPlayerScripts**.
2. Insert a **LocalScript**.
3. Rename it **`LobbyJoinNextMatchClient`**.
4. Paste from **[scripts/LobbyJoinNextMatchClient.local.lua](../scripts/LobbyJoinNextMatchClient.local.lua)**.

At run time it creates a ScreenGui named **`JoinNextMatch`** with a button **`OptInToggle`** (you do not need to build the GUI by hand).

**Who sees the button**

| Situation | Button |
|-----------|--------|
| **Lobby**, Neutral, no team | Visible — tap to opt **in** or **out** |
| Already on Red/Blue in lobby (should not happen with fresh **TeamAutoBalance**) | Hidden |
| **InMatch** and playing (`MatchParticipant` true) | Hidden |
| **InMatch** spectator (`MatchParticipant` false, Neutral, no team) | Visible — opts in for the **next** lobby countdown only (stays spectator this match) |

**Server rules**

- Player attribute **`JoinNextMatch`** (default **opted in** on **first join** only — server sets **`true`** when the attribute is still unset). An explicit **`false`** stays until the player taps opt-in again or **leaves and re-joins** the server.
- **RemoteEvent** **`SetJoinNextMatch`** under **`ReplicatedStorage/DodgeballRemotes`** (created by **LobbyService**). Works in **lobby** and for **InMatch spectators** (no team change until the next lobby countdown).
- Lobby countdown runs only when **at least 2** players have **`JoinNextMatch` true** — not merely 2 players in the server.
- When the countdown ends, only opted-in players get **Red/Blue** teams and arena spawns; everyone else stays a lobby spectator for that match (`MatchParticipant` **false**).
- **Opt-out persists** across lobby countdowns, match start, and match end — the server never flips **`false`** back to **`true`** except on **PlayerAdded** when the attribute was unset (new session / first time) or when the player uses **`SetJoinNextMatch`** to opt in. **`MatchParticipant`** handles who plays the current match; **`JoinNextMatch`** is only for the **next** countdown.
- Mid-match joiners can use the same button while the match runs; **`LobbyOptedInCount`** on **RoundStatus** still counts them so the next lobby countdown can start right away if enough players opted in early.

Re-paste **LobbyService**, **TeamAutoBalance**, **DodgeballConfig**, and **RoundStatusClient** when you update.

---

## Joining during a match

When **`MatchPhase`** is **`InMatch`** and a new player joins:

- They stay **Neutral** with **no** team (attribute **`MatchParticipant`** is **false**).
- They spawn and stay on the **lobby** pad — not Red/Blue arena spawns.
- **Round resets** and **intermissions** do **not** move them; only players in the match (`MatchParticipant` **true**) respawn on team pads.
- They cannot pick up or throw dodgeballs until the match ends.
- When the match ends → **lobby** phase → prior **`JoinNextMatch`** choices still count toward **`LobbyOptedInCount`** (or they can toggle the button anytime while spectating).

Re-paste **LobbyService**, **TeamAutoBalance**, **RoundService**, and **DodgeballService** after updating.

---

## Step 7 — How it plays

1. **Lobby** — Everyone spawns at your **lobby** pad. **Output** says `[LobbyService] Lobby phase`.
2. **Join next match** — New players are **opted in by default**. Tap the button only to **spectate** (opt out) for this lobby cycle.
3. **Countdown** — With **2 or more opted-in** players (default counts), a **30** second lobby timer runs (change in config).
4. **Not enough opted in** — Timer **pauses** and resets until **2+** have joined the next match (even if more players are standing in the lobby).
5. **One player left in server** — Same pause/reset until someone else joins.
6. **Match start** — Timer hits 0 → **`InMatch`** → **only opted-in** players load on **Red/Blue** spawns → **Round 1**; others stay lobby spectators for that match.
7. **Round win** — Same as step 5 (one team all OUT) → **+1 match point** for that team.
8. **Match win** — First team to **3** match points → back to **lobby**, scores **0**, everyone neutral; opt in again for the next countdown.

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
| `LobbyOptedInCount` | Players with **`JoinNextMatch` true** (updates during lobby and **InMatch**; used when the next lobby countdown starts) |
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

## Step 10 — Test with F5

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
2. **Player C**: tap **spectate** to opt **out**. **Players A & B** stay default opted in.
3. Confirm countdown runs; when it hits **0**, **A** and **B** spawn on arena pads; **C** stays on **LobbySpawn** and cannot throw.
4. Let the match finish → all return to lobby → **C** is **still opted out** until they tap opt-in (no server reset).

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
| Countdown never starts | Need **2+ opted-in** players (tap **Play next match** on two clients); check Output for pause message |
| Everyone in lobby but timer paused | At least **2** must opt in — spectators alone do not start the countdown |
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