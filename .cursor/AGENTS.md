# Cursor Cloud agents — roblox-dodgeball

Luau sources + colocated Studio docs per script. The game runs in **Roblox Studio**, not in this repo. No **Rojo** — humans paste from `scripts/<Name>/` into Explorer by **instance name**.

## Agent playbook

### Source of truth

| Area | Use |
|------|-----|
| `scripts/<Name>/*.lua` | Luau to paste (server, local, `scripts/throw/DefaultThrow/`) |
| `scripts/<Name>/<Name>.md` | Explorer path, human-built objects, config knobs, auto-created instances |
| `README.md` | System map and **Script / LocalScript / ModuleScript** paste targets |

**New human Studio objects** (spawn names, UI children, teams, folders) → update **only** that script’s colocated `.md` in its `scripts/<Name>/` folder. No numbered step guides.

**Gameplay-only change** with **no** new Explorer setup → doc edit not required.

**One feature → one PR.** Lua + markdown; do not add npm/node unless the task requires it.

### Repo folders vs Studio `require()`

GitHub uses nested folders for agents; Studio stays **flat by Explorer name** (`ServerScriptService/DodgeballConfig`, `ServerScriptService/throw/DefaultThrow`). Luau in this repo uses `WaitForChild("DodgeballConfig")` and `throw:WaitForChild("DefaultThrow")` — those names must match what humans paste. Do not switch to `script.Parent` repo-style requires unless Studio docs change too.

### Paste targets

Follow the scripts table in `README.md` (e.g. `ServerScriptService/DodgeballService` = **Script**, `StarterPlayerScripts/DodgeballThrowInput` = **LocalScript**, `ServerScriptService/throw/DefaultThrow` = **ModuleScript**). Object **names** must match the repo.

### Do not hand-build (scripts create these)

- `ReplicatedStorage/DodgeballRemotes` and its RemoteEvents  
- `ReplicatedStorage/RoundStatus` (attributes for UI and match state)  
- `ServerScriptService/DodgeballRoundBridge`  
- `ReplicatedStorage.BallPhysicsReplication` (BallPhysics server runtime RemoteEvent)

Duplicating them in docs or Studio instructions is wrong.

### BallPhysics (vendored)

- Source tree: `scripts/ball-physics/src/` → paste as **`ReplicatedStorage/BallPhysics`** ModuleScript tree ([ball-physics/README.md](../scripts/ball-physics/README.md)).
- Game tag for simulation: **`BALL_PHYSICS_TAG`** (default `PhysicsBall`); **DodgeballBallTemplate** adds it. Arena **`DODGEBALL_TAG`** / lobby **`LobbyPracticeBall`** stay as-is.
- Tuning: **`BALL_PHYSICS_*`** in **DodgeballConfig**; **BallPhysicsAutoSetup** copies into library `Config` at startup.
- Throws: **DefaultThrow** uses `ApplyImpulse` + optional `THROW_SIDE_SPIN_RAD_PER_SEC`; library applies aerodynamic forces — do not double-impulse for curve.
- Held balls: weld + zero velocity; simulator idles (no shim). Optional **PR #25** **DodgeballThrowerCollision** stacks independently.

### Architecture

Extend existing systems — **no parallel game framework:**

- **LobbyService**, **DodgeballService**, **LobbyPracticeBallService**, **RoundService**, **TeamAutoBalance**, shared **DodgeballConfig**, vendored **ReplicatedStorage/BallPhysics** + **BallPhysicsAutoSetup** / **BallPhysicsClient**, client LocalScripts under **StarterPlayerScripts** or **StarterGui** as documented.

**Semantics (do not confuse):**

- **`MatchParticipant`** — playing **this** match (arena). Spectators / mid-match lobby joiners: not a participant until the next match flow allows it.
- **`JoinNextMatch`** — queued for **next** lobby countdown. Default opt-in on first join; **`false` is explicit** and persists until the player toggles or rejoins.

**Spawns (human-built):**

- **Lobby pad:** **Neutral** on; find by `LOBBY_SPAWN_NAME` / `LOBBY_SPAWN_TAG` in **DodgeballConfig**.
- **Team pads:** **Neutral** off; **TeamColor** must match **Teams** (not just visual **Color**). Pad names are optional; matching is by **TeamColor**.

### Writing style

Beginner-friendly: plain words, short sentences. No kid/parent/lesson framing, no PR number or changelog voice in user-facing docs.

Prefer colocated `.md` over long Lua comments; a one-line `Studio setup: <Name>.md` header is fine.

### Verify (optional in cloud)

If tools are missing: `bash .cursor/install-tools.sh`, then from repo root:

```bash
stylua scripts/
selene scripts/ 2>/dev/null || true
```

Play test remains **F5** / multi-client in Studio — not in the cloud VM.

### Cloud environment

- Install script: `.cursor/install-tools.sh`. Network: account **Allow all network access** if installs fail.  
- No dev server to run in terminals for this project.