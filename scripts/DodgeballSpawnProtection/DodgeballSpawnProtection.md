# DodgeballSpawnProtection

**Explorer:** `ServerScriptService/DodgeballSpawnProtection` — **ModuleScript**

**Purpose:** Roblox **SpawnLocation** pads apply a default respawn **ForceField** (visible immunity sphere) when `Duration` &gt; 0. Dodgeball has no spawn immunity — this module sets every **SpawnLocation.Duration** to `0` and removes **ForceField** instances from player characters as soon as they load.

**Human setup:** None. Paste the module; **DodgeballService** and **LobbyService** `require` it at startup so hooks run before respawns.

**Not affected:** Ball **SpeedGlow** shells use `ForceField` **material** on ball Parts only; thrower no-collide grace (**DodgeballThrowerCollision**) is unrelated.