# Step 4 — Dodgeballs, pickup, throw, and “OUT”

You built the map and team script. Now add **dodgeballs on the ground**, **pick them up**, **aim and throw** at the other team, and mark players **out** when a fast throw hits them in time.

**Before you start:** Finish **[03-add-your-first-script](../03-add-your-first-script/README.md)** so **TeamAutoBalance** works.

Everything in this step is **server rules** (fair for everyone). **Aiming** (crosshair, power bar, hold timer) runs on your screen only—the **server** still decides if the throw is allowed and how strong it is.

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
| Throw + aim UI | `DodgeballThrowInput` | **StarterPlayer → StarterPlayerScripts** (LocalScript) |
| Aim UI (auto-created) | `DodgeballAimGui` | Your **PlayerGui** at run time (built by the LocalScript) |

Repo files to copy:

- [DodgeballConfig.lua](../scripts/DodgeballConfig.lua)
- [DodgeballService.server.lua](../scripts/DodgeballService.server.lua)
- [throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)
- [DodgeballThrowInput.local.lua](../scripts/DodgeballThrowInput.local.lua)

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

New kid-friendly tunables (with defaults):

| Config name | What it does |
|-------------|----------------|
| `AIM_POWER_CHARGE_SECONDS` | How long to hold aim to reach 100% power |
| `AIM_MAX_SECONDS` | Longest aim time — then auto-throw |
| `BALL_MAX_HOLD_SECONDS` | Pick up → you must start aiming before this runs out |
| `HOLD_PENALTY_PICKUP_COOLDOWN_SECONDS` | Can’t pick up after a “held too long” roll |
| `HOLD_PENALTY_SLOW_SECONDS` | How long you move slower after that roll |
| `HOLD_PENALTY_WALK_SPEED_MULTIPLIER` | Walk speed while slowed (0.5 = half speed) |
| `HOLD_ROLL_IMPULSE` | Gentle roll toward the other team (not an OUT throw) |
| `THROW_IMPULSE` | Max throw strength at 100% power (still in config) |

### throw folder + DefaultThrow

1. Under **ServerScriptService**, insert **Folder**, rename **`throw`**.
2. Inside `throw`, insert **ModuleScript**, rename **`DefaultThrow`**.
3. Paste from **[scripts/throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)**.

### DodgeballService

1. Under **ServerScriptService**, insert **Script** (not LocalScript), rename **`DodgeballService`**.
2. Paste from **[scripts/DodgeballService.server.lua](../scripts/DodgeballService.server.lua)**.

Leave **TeamAutoBalance** where it is—you need both scripts.

---

## Step 3 — LocalScript for aim, power, and throw

The server needs an **aim direction** and a **power number (0–1)**. This LocalScript:

- Shows a **hold bar** after pickup (start aiming before time runs out)
- **Hold** throw to **aim** (crosshair + locked mouse)
- Charges **power** while you hold aim
- **Release** (or hit max aim time) to throw from your **hand** toward the crosshair

1. In **Explorer**, open **StarterPlayer → StarterPlayerScripts**.
2. Insert **LocalScript**, rename **`DodgeballThrowInput`**.
3. Paste from **[scripts/DodgeballThrowInput.local.lua](../scripts/DodgeballThrowInput.local.lua)**.

**Important:** Keep **exactly one** `DodgeballThrowInput` LocalScript, and only under **StarterPlayerScripts** (not **StarterGui**). Delete any older throw LocalScripts with a different name or location.

**Controls in test:**

| Input | Action |
|-------|--------|
| **Hold F** or **hold left-click** | Aim (crosshair + power charge) |
| **Release** | Throw at current power |
| **Gamepad R2** (ButtonR2) | Same as hold-to-aim |

**UI names** (for checking in Explorer during Play):

- `DodgeballAimGui` → `Crosshair`, `HoldBarBackground`, `PowerBarBackground`

---

## Step 4 — What the rules do (kid words)

1. **Slow touch = pickup** — If a ball bumps you gently (under **PICKUP_MAX_SPEED**), you **hold** it on your right hand.
2. **Hold bar** — After pickup, a yellow bar counts down. **Start aiming** before **BALL_MAX_HOLD_SECONDS** or the ball **rolls** toward the other team’s side (not a throw — can’t get someone OUT).
3. **Held too long penalty** — Roll = short **slow walk** + **can’t pick up** for a few seconds.
4. **Aim** — Hold throw. Mouse locks to center; a ray from the camera through the screen center picks where you’re aiming (works in **1st** or **3rd** person).
5. **Power** — Blue bar fills to 100% over **AIM_POWER_CHARGE_SECONDS**. Bigger power = faster throw (**THROW_IMPULSE** × power).
6. **Release** — Server throws from your **hand** toward the aim point (not from the camera).
7. **Max aim time** — At **AIM_MAX_SECONDS**, the ball **auto-throws** at your crosshair and current power.
8. **Fast hit = maybe OUT** — During a throw, the server **sweeps** the ball path each frame. Enemy hits must be **fast enough** (**HIT_MIN_SPEED**) and **soon enough** (**THROW_OUT_WINDOW_SECONDS**).
9. **Same team** — Friendly hits do not eliminate.
10. **OUT** — If you’re out, the aim UI stays hidden until the round resets.

**After [step 6](../06-lobby-and-matches/README.md):** In **Lobby** or while spectating (**`MatchParticipant`** **false**), throws and aim UI stay off until a match starts and you’re playing.

Tweak numbers at the top of **DodgeballConfig** and test again.

---

## Step 5 — Test with F5

1. Save the place.
2. Press **F5** (Play).
3. Without the lobby from step 6, you can still test pickup and throw here (you must **not** be OUT).
4. Walk to a ball and **touch** it — it should stick near your hand; **yellow hold bar** appears at the bottom.
5. **Hold F** or **hold left-click** — **yellow crosshair** center screen + **blue power bar**; **release** to throw.
6. Let the **hold bar** run out **without** aiming — ball should roll away and you should be slowed briefly.
7. Open **Test → 2 Players** and try throwing at the other test player (different teams).

**While Play is running**, check **Explorer → Players → YourName → PlayerGui → DodgeballAimGui** — the ScreenGui should exist even before you pick up a ball.

**Output window:** Look for `[DodgeballThrowInput]` warnings (remotes missing, **StartAiming** missing). Warnings about no dodgeballs → check **`Workspace/Dodgeballs`**.

Press **Stop** when done.

---

## Step 6 — Studio layout cheat sheet

```
Workspace
  Dodgeballs/          ← folder
    Ball1              ← Part, Anchored off, CanCollide on, CanTouch on, tag Dodgeball
ServerScriptService
  TeamAutoBalance      ← from step 3
  DodgeballConfig      ← ModuleScript
  DodgeballService     ← Script
  throw/
    DefaultThrow       ← ModuleScript
StarterPlayer
  StarterPlayerScripts
    DodgeballThrowInput ← LocalScript (aim + throw)
ReplicatedStorage
  DodgeballRemotes/    ← created automatically at run time
    RequestThrow
    StartAiming
```

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Warning: no dodgeballs | Add Parts under **Workspace/Dodgeballs** or add tag **Dodgeball** |
| Pickup never happens | Ball moving too fast; lower **PICKUP_MAX_SPEED**; check **hold penalty** cooldown; after step 6, spectators cannot pick up |
| No hold bar at all | See **“No aim UI (bars / crosshair)”** below |
| Throw does nothing | **DodgeballThrowInput** running? **Output** `[DodgeballThrowInput]` warnings? After step 6: must be **InMatch** with **MatchParticipant** true |
| No crosshair | You must **hold** F or left-click, not tap once |
| Hits never eliminate | See **“Ball hits but no OUT”** below |
| Weak throws | Hold aim longer for more power; check **THROW_IMPULSE** |

### No aim UI (bars / crosshair)

Use this **Studio checklist** when the ball sticks to your hand but you see no yellow hold bar, blue power bar, or crosshair:

1. **One LocalScript only** — `DodgeballThrowInput` under **StarterPlayer → StarterPlayerScripts**. Remove duplicates from **StarterGui**, **StarterCharacterScripts**, or an old step 4 script with a different name.
2. **Latest files pasted** — Replace **DodgeballService** (creates **DodgeballRemotes** with **RequestThrow** and **StartAiming**) and **DodgeballThrowInput** from this repo.
3. **Output warnings** — After **F5**, if you see `[DodgeballThrowInput] DodgeballRemotes folder missing`, **DodgeballService** is not running or errored on load. If you see **StartAiming remote missing**, your **DodgeballService** copy is older than this repo — paste again.
4. **After step 6** — Wait until **MatchPhase** is **InMatch** and you spawned on a team pad. See **[06-lobby-and-matches](../06-lobby-and-matches/README.md)** if the button says you’re spectating.
5. **F5 verification** — Pick up a ball: bottom **HoldBarBackground** should show. **Hold** throw: center **Crosshair** + **PowerBarBackground**. If **DodgeballAimGui** is missing under **PlayerGui**, the LocalScript did not run — check placement and Output errors.

### Ball hits but no OUT

Fast throws often **never fire Touched** (the ball tunnels through the player between physics steps). Even when Touched runs, it can be **late** or the ball can have the **wrong network owner**, so scripts that only listen to Touched miss the hit.

**Fix:** Copy the latest files from this repo into Studio again (replace what you have):

1. **[DodgeballConfig.lua](../scripts/DodgeballConfig.lua)** → `DodgeballConfig`
2. **[DodgeballService.server.lua](../scripts/DodgeballService.server.lua)** → `DodgeballService`
3. **[throw/DefaultThrow.lua](../scripts/throw/DefaultThrow.lua)** → `DefaultThrow`
4. **[DodgeballThrowInput.local.lua](../scripts/DodgeballThrowInput.local.lua)** → `DodgeballThrowInput`

The service uses **server spherecast sweeps** while the ball is in the throw window. **Touched** is only for **slow pickup** when nobody just threw the ball. On each ball Part, keep **CanTouch** and **CanCollide** on.

**Still stuck?**

- Test with **Test → 2 Players**; players must be on **different teams**.
- Check **HIT_MIN_SPEED** (default 25). Full-power **THROW_IMPULSE** (default 80) should stay above it.
- Set **`DEBUG_ELIMINATION = true`** in `DodgeballConfig` and watch **Output**.

---

## What is next?

Continue to **[05-round-reset](../05-round-reset/README.md)** for rounds and respawn, or read **[WHATS-NEXT.md](../WHATS-NEXT.md)** for the full roadmap.

Back: **[README.md](../README.md)**.