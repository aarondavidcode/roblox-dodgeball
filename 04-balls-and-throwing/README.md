# Step 4 — Dodgeballs, pickup, throw, and “OUT”

You built the map and team script. Now add **dodgeballs on the ground**, **pick them up**, **throw** at the other team, and mark players **out** when a fast throw hits them in time.

**Before you start:** Finish **[03-add-your-first-script](../03-add-your-first-script/README.md)** so **TeamAutoBalance** works.

Everything in this step is **server rules** (fair for everyone). Throw **aim** uses one small **LocalScript** on your screen only—the server still decides if the throw is allowed.

---

## What you are adding

| Thing in Studio | Exact name | Where it lives |
|-----------------|------------|----------------|
| Ball storage folder | `Dodgeballs` | **Workspace** |
| Each ball | Any name (e.g. `Ball1`) | Inside **Dodgeballs** |
| Optional tag | `Dodgeball` | **Tags** on each ball (recommended) |
| Tunable numbers | `DodgeballConfig` | **ServerScriptService** (ModuleScript) |
| Game logic | `DodgeballService` | **ServerScriptService** (Script) |
| Default throw | `DefaultThrow` | **ServerScriptService → throw** (ModuleScript) |
| Throw aim helper | `DodgeballThrowInput` | **StarterPlayer → StarterPlayerScripts** (LocalScript) |

Repo files to copy:

- [DodgeballConfig.lua](../scripts/DodgeballConfig.lua)
- [DodgeballService.server.lua](../scripts/DodgeballService.server.lua)
- [throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)

---

## Step 1 — Build balls in Workspace

1. In **Explorer**, click **Workspace**.
2. Insert a **Folder** and rename it **`Dodgeballs`** (spelling matters).
3. Insert a **Part** inside the folder.
4. In **Properties** for the Part:
   - **Anchored** = **off** (unchecked)
   - **CanCollide** = **on**
   - **CanTouch** = **on** (so slow rolling pickup still works)
   - Shape: **Ball** (optional neon Material for fun)
   - Size: about `2, 2, 2` studs (tweak to taste)
5. Duplicate the Part for more balls (Ctrl+D).

**Tags (recommended):**

1. With a ball selected, open **Properties** → **Tags** (or View → Tags).
2. Add tag **`Dodgeball`** (must match the config file).

The server watches the **Dodgeballs** folder and anything tagged **`Dodgeball`**.

---

## Step 2 — Add ModuleScripts and the service script

### DodgeballConfig

1. Under **ServerScriptService**, insert **ModuleScript**, rename **`DodgeballConfig`**.
2. Paste from **[scripts/DodgeballConfig.lua](../scripts/DodgeballConfig.lua)**.

### throw folder + DefaultThrow

1. Under **ServerScriptService**, insert **Folder**, rename **`throw`**.
2. Inside `throw`, insert **ModuleScript**, rename **`DefaultThrow`**.
3. Paste from **[scripts/throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)**.

### DodgeballService

1. Under **ServerScriptService**, insert **Script** (not LocalScript), rename **`DodgeballService`**.
2. Paste from **[scripts/DodgeballService.server.lua](../scripts/DodgeballService.server.lua)**.

Leave **TeamAutoBalance** where it is—you need both scripts.

---

## Step 3 — LocalScript for throw (F or click)

The server will **not** trust your computer to say someone is out—but it **does** need a direction to throw. This LocalScript only sends “throw that way” after you press a key or click.

1. In **Explorer**, open **StarterPlayer → StarterPlayerScripts**.
2. Insert **LocalScript**, rename **`DodgeballThrowInput`**.
3. Paste all of this:

```lua
-- LocalScript: DodgeballThrowInput under StarterPlayerScripts
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local remotes = ReplicatedStorage:WaitForChild("DodgeballRemotes", 10)
if not remotes then
	warn("[DodgeballThrowInput] DodgeballRemotes folder missing — is DodgeballService running?")
	return
end
local throwRemote = remotes:WaitForChild("RequestThrow", 10) :: RemoteEvent

local function throwWhereYouLook()
	if not camera then
		return
	end
	local direction = camera.CFrame.LookVector
	throwRemote:FireServer(direction)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end
	-- F key or left mouse button
	if input.KeyCode == Enum.KeyCode.F or input.UserInputType == Enum.UserInputType.MouseButton1 then
		throwWhereYouLook()
	end
end)
```

**Controls in test:** Look where you want to throw, press **F** or **left-click**.

---

## Step 4 — What the rules do (kid words)

1. **Slow touch = pickup** — If a ball bumps you gently (under **PICKUP_MAX_SPEED** in config), you **hold** it on your right hand.
2. **One ball each** — You can only hold one ball at a time.
3. **Throw** — Press **F** or **click**. The server releases the ball and adds speed (**DefaultThrow** module).
4. **Fast hit = maybe OUT** — During a throw, the server **sweeps** the ball path each frame (not **Touched**) so fast throws still count. Enemy hits must be **fast enough** (**HIT_MIN_SPEED**) and **soon enough** (**THROW_OUT_WINDOW_SECONDS**). That player is **OUT** (`IsOut` attribute, cannot move).
5. **Old rolls don’t count** — A ball rolling on the ground after the time window is just a pickup, not an elimination (only **instant** speed is used then).
6. **Same team** — Friendly hits do not eliminate.

Tweak numbers at the top of **DodgeballConfig** and test again.

---

## Step 5 — Test with F5

1. Save the place.
2. Press **F5** (Play).
3. Walk to a ball and **touch** it — it should stick near your hand.
4. Look at a wall and press **F** or **click** — the ball should fly.
5. Open **Test → 2 Players** and try throwing at the other test player (different teams).

**Output window:** If you see a warning about no dodgeballs, check **`Workspace/Dodgeballs`** has Parts inside.

Press **Stop** when done.

---

## Step 6 — Studio layout cheat sheet

```
Workspace
  Dodgeballs/          ← folder
    Ball1              ← Part, Anchored off, CanCollide on, CanTouch on, tag Dodgeball
    Ball2
ServerScriptService
  TeamAutoBalance      ← from step 3
  DodgeballConfig      ← ModuleScript
  DodgeballService     ← Script
  throw/
    DefaultThrow       ← ModuleScript
StarterPlayer
  StarterPlayerScripts
    DodgeballThrowInput ← LocalScript (throw aim)
ReplicatedStorage
  DodgeballRemotes/    ← created automatically at run time
    RequestThrow
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Warning: no dodgeballs | Add Parts under **Workspace/Dodgeballs** or add tag **Dodgeball** |
| Pickup never happens | Ball might be moving too fast; lower **PICKUP_MAX_SPEED** or let ball settle |
| Throw does nothing | Check **DodgeballThrowInput** LocalScript and **Output** for errors |
| Hits never eliminate | See **“Ball hits but no OUT”** below |
| Everyone on same team hits | Only **opposite** teams count; check Teams in Explorer |

### Ball hits but no OUT

Fast throws often **never fire Touched** (the ball tunnels through the player between physics steps). Even when Touched runs, it can be **late** or the ball can have the **wrong network owner**, so scripts that only listen to Touched miss the hit.

**Fix:** Copy the latest three files from this repo into Studio again (replace what you have):

1. **[DodgeballConfig.lua](../scripts/DodgeballConfig.lua)** → ModuleScript `DodgeballConfig`
2. **[DodgeballService.server.lua](../scripts/DodgeballService.server.lua)** → Script `DodgeballService`
3. **[throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)** → ModuleScript `DefaultThrow` under `throw`

The service uses **server spherecast sweeps** while the ball is in the throw window. **Touched** is only for **slow pickup** when nobody just threw the ball. On each ball Part, keep **CanTouch** and **CanCollide** on.

**Still stuck?**

- Test with **Test → 2 Players**; players must be on **different teams** (TeamAutoBalance from step 3).
- Check **HIT_MIN_SPEED** in config (default 25). **THROW_IMPULSE** (default 80) should stay above it.
- Set **`DEBUG_ELIMINATION = true`** in `DodgeballConfig` and watch **Output** for throw start, sweep hits, blocked eliminations, and successes.

---

## What is next?

Read **[WHATS-NEXT.md](../WHATS-NEXT.md)** for round reset, lobby flow, and polish. Your map can always grow—scripts add new rules one milestone at a time.

Back: **[README.md](../README.md)**.