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

**What is new (kid words):**

- When the game starts, each ball remembers **where it was standing** (`SpawnCFrame` attribute).
- A hidden folder **DodgeballRoundBridge** appears under **ServerScriptService** at run time — **RoundService** talks to it. You do not paste anything there; it is automatic.

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
4. **Reset** — Drop held balls → clear OUT → move balls back to spawn → **LoadCharacter** so you land on your team’s spawn pad (from step 2).
5. **New round** — **RoundNumber** goes up by 1.

Watch **Output** for lines like `[RoundService] Round 1 over — Blue wins!`

---

## Step 5 — Optional RoundStatus UI (countdown text)

This is only on **your** screen — copy-paste friendly.

1. Under **StarterGui**, insert **ScreenGui**, rename **`RoundStatus`**.
2. Inside it, insert **TextLabel**, rename **`CountdownLabel`**.
3. Set **CountdownLabel** Properties (rough guide):
   - **Size** = `{0.4, 0}, {0.08, 0}` (scale)
   - **Position** = `{0.3, 0}, {0.05, 0}`
   - **BackgroundTransparency** = `0.3`
   - **TextScaled** = on
   - **Text** = `Round 1`
4. Insert a **LocalScript** inside **RoundStatus**, rename **`RoundStatusClient`**.
5. Paste:

```lua
-- LocalScript: RoundStatusClient inside StarterGui/RoundStatus
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local label = script.Parent:WaitForChild("CountdownLabel") :: TextLabel
local roundFolder = ReplicatedStorage:WaitForChild("RoundStatus", 30)
if not roundFolder then
	warn("[RoundStatus] RoundStatus folder missing — is RoundService running?")
	return
end

local function refresh()
	local state = roundFolder:GetAttribute("RoundState")
	local roundNum = roundFolder:GetAttribute("RoundNumber")
	if typeof(roundNum) ~= "number" then
		roundNum = 1
	end

	if state == "Intermission" then
		local endsAt = roundFolder:GetAttribute("IntermissionEndsAt")
		if typeof(endsAt) == "number" then
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			label.Text = `Next round in {left}...`
		else
			label.Text = "Next round soon..."
		end
	elseif state == "Resetting" then
		label.Text = "Resetting..."
	else
		label.Text = `Round {roundNum} — PLAY!`
	end
end

roundFolder:GetAttributeChangedSignal("RoundState"):Connect(refresh)
roundFolder:GetAttributeChangedSignal("RoundNumber"):Connect(refresh)
roundFolder:GetAttributeChangedSignal("IntermissionEndsAt"):Connect(refresh)

task.spawn(function()
	while true do
		refresh()
		task.wait(0.25)
	end
end)

refresh()
```

---

## Step 6 — Test with F5 and 2 Players

1. Save the place.
2. Press **F5** (Play).
3. Open **View → Output** — you should see `[RoundService] Watching for round wins`.
4. Use **Test → 2 Players** (different teams from **TeamAutoBalance**).
5. Throw until one team is all OUT.
6. Watch the countdown (if you added UI), then both players respawn and balls return to start spots.

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

See **[WHATS-NEXT.md](../WHATS-NEXT.md)** for lobby flow, special throws, and spectator zones.

Back: **[README.md](../README.md)**.