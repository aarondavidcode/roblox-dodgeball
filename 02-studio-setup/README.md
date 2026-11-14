# Step 2 — Roblox Studio setup

This guide is for kids and parents building a **two-team dodgeball** place. You will learn the main Studio windows, add **Red** and **Blue** teams with spawns on opposite sides of your arena, and get ready for your first team script.

---

## What you need first

1. Install **Roblox Studio** from [create.roblox.com](https://create.roblox.com) (use a parent’s Roblox account if you are under 13).
2. Sign in to Studio with the same account you use to play Roblox.
3. Keep this page open next to Studio so you can follow the steps in order.

---

## Open Studio and start a place

1. Open **Roblox Studio** from your computer’s app list.
2. On the **Home** screen, click **New**.
3. Under **Gameplay** (or **Baseplate**), click **Baseplate** for a flat world with grass and sky.  
   - **Empty Baseplate** or **Classic Baseplate** also work if you see them—pick one that gives you a floor you can build on.
4. Wait until the 3D view loads. You should see a gray baseplate and a **SpawnLocation** (a flat colored pad).

**Tip:** To save later, use **File → Save to Roblox** or **Save to File** on your computer.

If you have not built your arena yet, you can still do teams and spawns now, or go back to **[01-build-your-map](../01-build-your-map/README.md)** anytime.

---

## Find the main panels (Explorer, Properties, Toolbox)

Studio hides panels until you open them. Everything below uses the **View** tab.

1. Click the **View** tab at the top of Studio.
2. Turn on **Explorer** (a list of every object in your game).
3. Turn on **Properties** (settings for whatever you click in Explorer).
4. Turn on **Toolbox** if you want free models from the Creator Store (optional for dodgeball map building).

**What each one does**

| Panel | What it is |
|--------|------------|
| **Explorer** | A tree of folders and parts (like `Workspace`, `Teams`). |
| **Properties** | Numbers and checkboxes for the selected item (size, color, team, etc.). |
| **Toolbox** | Drag-in models and assets (use carefully—stick to simple parts when learning). |

If a panel disappears again, go back to **View** and click its name.

---

## Words we use in this project (short glossary)

- **Server** — The shared “game brain” that runs the same rules for **everyone**. Scripts that live in **ServerScriptService** run on the server. Team picking for dodgeball belongs here.
- **LocalScript** — Code that runs on **one player’s screen only** (UI, camera effects). We are **not** using LocalScripts for team balance yet.
- **Workspace** — The 3D world players walk around in (your arena, walls, dodgeballs later).
- **Play (F5)** — Test your game inside Studio.

---

## Add two teams: Red and Blue

Teams are objects in a special folder called **Teams**, not regular parts in the world.

1. In **Explorer**, find **Teams** (near the top). Click the small **+** next to it.
2. Click **Team** to insert one Team.
3. With that Team selected, look at **Properties**:
   1. Set **Name** to `Red` (spelling matters for our script).
   2. Set **TeamColor** to a red brick color (for example **Really red**).
   3. Leave **AutoAssignable** **unchecked** (our script will pick the team).
4. Insert a second **Team** under **Teams**.
   1. Set **Name** to `Blue`.
   2. Set **TeamColor** to a blue brick color (for example **Really blue**).
   3. Leave **AutoAssignable** **unchecked**.

Each team must have a **different** **TeamColor**—Roblox uses that color like an ID card for the team.

---

## Build your arena (kids’ job)

1. In **Workspace**, add parts or models for your dodgeball court (floors, walls, center line—whatever your family designs).
2. Leave **two open areas** on **opposite sides** of the arena—one side for Red, one for Blue.
3. You can delete or move the default spawn in the middle later if it gets in the way (select it in **Workspace**, press **Delete**).

More ideas: **[01-build-your-map](../01-build-your-map/README.md)**.

---

## Add team spawn pads (SpawnLocation)

You need **one spawn pad per team**, on opposite sides of the arena.

### Red spawn

1. In **Explorer**, select **Workspace**.
2. Click **+** next to Workspace → choose **SpawnLocation** (or **Part**, then change its class—SpawnLocation is easier).
3. Rename it in Explorer to `RedSpawn` (names help you stay organized).
4. Use the **Move** tool to place it on the **Red side** of your arena.
5. In **Properties** for `RedSpawn`:
   1. Check **Anchored** so it does not fall.
   2. Resize **Size** if you want a bigger pad (for example 6, 1, 6).
   3. **Uncheck Neutral** — only Red players should spawn here.
   4. Set **TeamColor** to the **same** brick color as your **Red** team’s **TeamColor** (for example **Really red**).

### Blue spawn

1. Insert another **SpawnLocation** into **Workspace**.
2. Rename it to `BlueSpawn`.
3. Move it to the **Blue side**, **opposite** Red.
4. In **Properties**:
   1. Check **Anchored**.
   2. **Uncheck Neutral**.
   3. Set **TeamColor** to match the **Blue** team’s **TeamColor** (for example **Really blue**).

### Critical pitfall: TeamColor vs Color (read this with a grown-up)

Roblox has **two different “color” ideas** on a SpawnLocation:

| Property | What it does |
|----------|----------------|
| **TeamColor** | **Gameplay:** “Which team may spawn here?” Must **match** the team’s **TeamColor**. |
| **Color** / **BrickColor** | **Looks only:** What color the pad appears in the world. Does **not** choose the team. |

From [Roblox’s teams documentation](https://create.roblox.com/docs/players/teams): changing **Color** or **BrickColor** only changes how the pad looks. If players spawn on the wrong side or anyone can use a pad, fix **TeamColor** and **Neutral**, not the visual color.

**Easy check:** Select your Red team in **Teams** and note its **TeamColor**. Select `RedSpawn` and make sure **TeamColor** is identical—not just “red-looking” **Color**.

---

## Turn on team-related game settings (if teams act broken)

Usually, creating **Team** objects is enough. If players never get a team color in the player list, or everyone spawns in the wrong place:

1. Click **Home** → **Game Settings** (or **File → Game Settings**).
2. Open the **Avatar** section and confirm nothing is blocking normal spawning (defaults are fine for most dodgeball places).
3. Open the **World** section and check spawn/character options still allow respawning (defaults are usually OK).
4. In **StarterPlayer** (in Explorer), you can set **CharacterAutoLoads** to **true** so characters appear when players join (default is often already true).

Save settings with **Save** at the bottom of the Game Settings window.

---

## Add a place for server scripts (preview)

Our first script will live in **ServerScriptService** (server = rules for everyone).

1. In **Explorer**, find **ServerScriptService**.
2. You will add a **Script** there in the next step: **[03-add-your-first-script](../03-add-your-first-script/README.md)**.  
   - **Do not** use **LocalScript** for team balancing.

---

## Quick checklist before you script

1. **Teams** service has teams named exactly `Red` and `Blue`.
2. Each team has a unique **TeamColor**.
3. `RedSpawn` and `BlueSpawn` are in **Workspace**, on opposite sides.
4. Both spawns: **Neutral** is **off**, **TeamColor** matches the team (not just visual **Color**).
5. **Explorer**, **Properties**, and **View** tab are available when you need them.

**Next:** **[03-add-your-first-script](../03-add-your-first-script/README.md)**.