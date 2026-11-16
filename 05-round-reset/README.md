# Step 5 — Round reset (win, countdown, respawn)

You can already throw dodgeballs and mark players **OUT**. This step adds **rounds**: when **everyone on one team** is OUT, the other team wins, you get a short **countdown**, then everyone respawns, balls go back to their start spots, and a new round begins.

**Before you start:** Finish **[04-balls-and-throwing](../04-balls-and-throwing/README.md)** (DodgeballService, balls, OUT rules).

---

## What you are adding

| Thing in Studio | Exact name | Where it lives |
|-----------------|------------|----------------|
| Updated numbers | `DodgeballConfig` | **ServerScriptService** (paste fresh copy) |
| Updated game logic | `DodgeballService` | **ServerScriptService** (paste fresh copy) |
| Round logic | `RoundService` | **ServerScriptService** (Script) |
| Optional UI | `RoundStatus` | **StarterGui** (ScreenGui + LocalScript) |

Repo files to copy:

- [DodgeballConfig.lua](../scripts/DodgeballConfig.lua) — **replace** your old config (new round settings at the bottom)
- [DodgeballService.server.lua](../scripts/DodgeballService.server.lua) — **replace** your step 4 script (ball spawn memory + round bridge)
- [RoundService.server.lua](../scripts/RoundService.server.lua) — **new** script

Leave **TeamAutoBalance**, **throw/DefaultThrow**, and **DodgeballThrowInput** as they are.

---

## Step 1 — Update DodgeballConfig

1. Select **DodgeballConfig** in **ServerScriptService**.
2. Select all code in the script editor and delete it.
3. Paste from **[scripts/DodgeballConfig.lua](../scripts/DodgeballConfig.lua)** on GitHub.

Look at the bottom for **Round reset** settings:

- **ROUND_INTERMISSION_SECONDS** — countdown after a win (set to `0` to skip).
- **TEAM_NAMES** — must stay `Red` and `Blue` if that is what you use in Explorer.

---

## Step 2 — Update DodgeballService

1. Select **DodgeballService** in **ServerScriptService**.
2. Replace all code with **[scripts/DodgeballService.server.lua](../scripts/DodgeballService.server.lua)**.

**What it adds (kid words):**

- When the game starts, each ball remembers **where it was standing** (`SpawnCFrame` attribute).
- A hidden folder **DodgeballRoundBridge** appears under **ServerScriptService** at run time — **RoundService** talks to it. You do not paste anything there; it is automatic.
- OUT hits during throws still use **spherecast sweeps** from step 4; round reset turns those off and puts balls back.

---

## Step 3 — Add RoundService

1. Under **ServerScriptService**, insert a **Script** (not LocalScript).
2. Rename it **`RoundService`**.
3. Paste from **[scripts/RoundService.server.lua](../scripts/RoundService.server.lua)**.

You should now have **three** server scripts: **TeamAutoBalance**, **DodgeballService**, **RoundService**.

---

## Step 4 — What the rules do

1. **Win** — If **every** player on **Red** is OUT and at least one **Blue** player is still in (not OUT), **Blue wins**. Same the other way around.
2. **Tie** — If **everyone** in the server is OUT, wait a moment (**ROUND_TIE_RESET_DELAY_SECONDS**), then reset anyway.
3. **Intermission** — Optional countdown; status is stored on **ReplicatedStorage/RoundStatus** (`RoundState`, `RoundNumber`, `IntermissionEndsAt`).
4. **Reset** — Drop held balls → clear OUT → move balls back to spawn → respawn players on their team pads (from step 2).
5. **New round** — **RoundNumber** goes up by 1.

**Important:** **RoundService** waits until a match is live (`MatchPhase` **InMatch**, set in **[step 6](../06-lobby-and-matches/README.md)**). Until then, Output says it is waiting—OUT rules from step 4 still work, but win/reset cycles do not run yet.

Watch **Output** for lines like `[RoundService] Round 1 over — Blue wins!`

---

## Step 5 — Optional RoundStatus UI (countdown text)

This is only on **your** screen — copy-paste friendly. You build the ScreenGui once here; **[step 6](../06-lobby-and-matches/README.md)** tells you when to paste the newer **RoundStatusClient** for lobby text and match scores.

### Hierarchy (exact names)

```
StarterGui
  RoundStatus          ← ScreenGui
    CountdownLabel     ← TextLabel (clear **Text** so it stays empty until the script runs)
    RoundStatusClient  ← LocalScript (must be **LocalScript**, not Script)
```

### What you see during an arena round (step 6 match running)

| Server state | On-screen text (examples) |
|--------------|---------------------------|
| **InMatch** + **Playing** | `Red 0 · Blue 0 (first 3) · Round 1 — PLAY!` |
| **InMatch** + **Intermission** | Match score + seconds until next round |
| **InMatch** + **Resetting** | Match score + `Resetting arena…` |

Lobby countdown and opt-in counts are configured in **[step 6](../06-lobby-and-matches/README.md)** (same **CountdownLabel**, newer client script).

Data comes from **`ReplicatedStorage/RoundStatus`** attributes (`RoundState`, `RoundNumber`, scores, and later `MatchPhase`).

### Build it in Studio

1. Under **StarterGui**, insert **ScreenGui**, rename **`RoundStatus`**.
2. Inside it, insert **TextLabel**, rename **`CountdownLabel`** (not `Label` or `StatusLabel`).
3. Set **CountdownLabel** Properties (rough guide):
   - **Size** = `{0.55, 0}, {0.08, 0}` (scale)
   - **Position** = `{0.225, 0}, {0.05, 0}`
   - **BackgroundTransparency** = `0.3`
   - **TextScaled** = on
   - **Text** = *(leave empty)*
4. Insert **LocalScript** inside **RoundStatus**, rename **`RoundStatusClient`**.
5. Copy all code from **[scripts/RoundStatusClient.local.lua](../scripts/RoundStatusClient.local.lua)** on GitHub and paste into the LocalScript.

If the label still says **"Label"**, you renamed the wrong object or the script could not find **`CountdownLabel`** — check **Output** for `[RoundStatusClient]` warnings.

---

## Step 6 — Test with F5

1. Save the place.
2. Press **F5** (Play).
3. Open **View → Output** — you should see `[RoundService] Waiting for lobby match start` (round wins start after **[step 6](../06-lobby-and-matches/README.md)**).
4. Use **Test → 2 Players** and confirm **DodgeballService** still marks players OUT when hit.
5. Finish **step 6**, then repeat with a live match: throw until one team is all OUT, watch intermission, then respawn and ball reset.

**Stop** when done.

---

## Studio layout cheat sheet

```
ServerScriptService
  TeamAutoBalance
  DodgeballConfig
  DodgeballService
  RoundService                    ← new
  DodgeballRoundBridge/           ← auto at run time (do not paste)
  throw/
    DefaultThrow
ReplicatedStorage
  DodgeballRemotes/
  RoundStatus/                    ← auto (attributes for UI)
Workspace
  Dodgeballs/
StarterGui (optional)
  RoundStatus/
    CountdownLabel
    RoundStatusClient             ← LocalScript
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Round never ends | Make sure **every** player on one team has `IsOut` in Properties while testing |
| Balls do not return | Re-paste **DodgeballService**; balls need **SpawnCFrame** saved on first play |
| No countdown folder | **RoundService** must run; check Output for errors |
| Players spawn wrong team | Re-check **SpawnLocation** **TeamColor** in [02-studio-setup](../02-studio-setup/README.md) |
| Config errors | **DEFAULT_WALK_SPEED** / round keys only exist in the new **DodgeballConfig** — paste the full file |

---

## What is next?

**Next:** **[06-lobby-and-matches](../06-lobby-and-matches/README.md)** — lobby, opt-in button, and full round cycles.

Back: **[README.md](../README.md)**.