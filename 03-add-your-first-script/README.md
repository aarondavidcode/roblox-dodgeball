# Step 3 — First script: auto-balance Red and Blue

This walkthrough connects your Studio setup to one server script. When a player joins, the game puts them on the **smaller** team so Red and Blue stay fair for dodgeball.

**Before you start:** Finish **[02-studio-setup](../02-studio-setup/README.md)** so you have teams `Red` and `Blue`, spawns `RedSpawn` and `BlueSpawn`, and **Neutral** turned off on those spawns.

---

## What you are adding

| Thing in Studio | Exact name | Where it lives |
|-----------------|------------|----------------|
| Red team | `Red` | **Teams** |
| Blue team | `Blue` | **Teams** |
| Red spawn pad | `RedSpawn` (your choice, but spawns must match team colors) | **Workspace** |
| Blue spawn pad | `BlueSpawn` | **Workspace** |
| Team balance script | `TeamAutoBalance` | **ServerScriptService** |

The script file lives in this repo: **[TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua)** (open it on GitHub and copy all the code).

---

## Step 1 — Double-check teams and spawns

1. Open **Explorer**.
2. Under **Teams**, click **Red**. In **Properties**, note **TeamColor** (for example **Really red**).
3. Click **Blue** and note its **TeamColor**.
4. Click `RedSpawn` in **Workspace**. Confirm **Neutral** is **unchecked** and **TeamColor** equals Red’s **TeamColor**.
5. Click `BlueSpawn`. Same checks for Blue.

If anything fails the spawn pitfall from the setup guide, fix **TeamColor** on the spawn—not only **Color**.

---

## Step 2 — Create the script object

1. In **Explorer**, find **ServerScriptService**.
2. Hover over **ServerScriptService** and click **+**.
3. Choose **Script** (not LocalScript, not ModuleScript).
4. Click the new script, press **F2** (or slow double-click), and rename it to **`TeamAutoBalance`**.

---

## Step 3 — Paste the code

1. Select **TeamAutoBalance** in Explorer.
2. Open the script editor (double-click the script).
3. Delete any default text inside (often `print("Hello world!")`).
4. On GitHub, open **[scripts/TeamAutoBalance.server.lua](../scripts/TeamAutoBalance.server.lua)**.
5. Click **Raw** (or select all in the file view), copy **all** the code, and paste it into the Studio script.
6. Save the place: **File → Save to Roblox** or **Save to File**.

The first lines of the file remind you: this must be a **Script** named **TeamAutoBalance** under **ServerScriptService**.

---

## Step 4 — What the script does (in kid words)

1. When someone joins, it counts players on Red and Blue.
2. It puts the new player on the team with **fewer** players (tie goes to Red first—that’s just how we coded it).
3. It sets **Neutral** to **false** **before** **Team** (Roblox’s recommended order so the player list and spawns work).
4. If **CharacterAutoLoads** is on (default), Roblox spawns you on the right **SpawnLocation** after team is set. If you already spawned in the wrong place, the script respawns you once.
5. When someone leaves, we do not need extra code—the counts update on the next join.

**Optional (tricky neutral spawns):** In **Explorer → StarterPlayer**, you can set **CharacterAutoLoads** to **false** and let the script call **LoadCharacter** after picking a team. The updated script works with the default **true** as well.

When you test alone, you are only one player—the script still picks Red or Blue for you.

---

## Step 5 — Test with Play (F5), one player

1. Click the **Play** button or press **F5** (testing tab may show **Play** at the top).
2. Wait for your character to load.
3. Look at the **player list** (top right in the test game). You should see your name on **Red** or **Blue** (solo test: first player is usually **Red** when counts are tied—not **Neutral**).
4. Check that you spawned on the **matching** side of the arena (Red spawn pad for Red, etc.).
5. Press **Stop** (red square) or **Shift+F5** to end the test.

If you spawn in the wrong place, stop the test and re-check spawn **TeamColor** and **Neutral** from the setup guide.

---

## Step 6 — Test with two players (Studio multiplayer)

Studio can pretend two people joined so you can see balancing work.

1. Go to the **Test** tab (next to **Home**, **Model**, **Avatar**, etc.).
2. Open the **Clients and Servers** dropdown (sometimes shows **1 Player** by default).
3. Choose **2 Players** (or **Start** with 2 players—wording may be **2 Players** under test options).
4. Press **Play** / **Start**.
5. Studio opens a server view and a second client window (or splits the screen). Watch **both** player lists.
6. The **first** player usually lands on one team; the **second** should land on the **other** team if counts are uneven.
7. Press **Stop** when finished.

**Late join in a real game:** The same rules apply—each new joiner goes to the smaller team. In a 2-player Studio test, join order matters: player 1 might be Red, player 2 Blue.

**Players already in the game when you edit the script:** Stop play, paste an updated script if needed, and play again. The script also balances anyone already connected when the server starts (helpful if you hit Play before the script was there).

---

## Step 7 — Publish (optional, with a parent)

1. **File → Publish to Roblox**.
2. Pick a name for your dodgeball place and follow the prompts.
3. On the website, set the experience to **Private** until your family is ready to invite friends.

See also **[FOR-PARENTS.md](../FOR-PARENTS.md)**.

---

## Troubleshooting

| Problem | What to try |
|---------|-------------|
| Error in **Output** window about `Red` or `Blue` | Team **Names** must be exactly `Red` and `Blue` (capital R and B). |
| Name shows **Neutral** in the player list | Teams missing or misspelled; check **Output** for `[TeamAutoBalance]` warnings. Paste the latest script from GitHub (waits for teams, sets **Neutral** before **Team**). |
| Spawned in the **middle** or default pad | Delete or disable the **baseplate** SpawnLocation, or turn **Neutral** **off** on team spawns only. Middle pads often have **Neutral** **on**, so anyone can spawn there. |
| Everyone spawns on the same pad | Each spawn **Neutral** off; **TeamColor** matches the team—not just pad **Color**. |
| Script does nothing | Script must be under **ServerScriptService**, type **Script**, not LocalScript. |
| Second player same team every time | Test with **2 Players**; first joiner fills one side, second should balance. |

---

## What is next?

Read **[WHATS-NEXT.md](../WHATS-NEXT.md)** for dodgeball features to add later (ball tool, out-of-bounds, round reset).