-- Studio setup: DodgeballConfig.md
-- Paste this as a ModuleScript named DodgeballConfig under ServerScriptService.
-- Change the numbers below to tune how dodgeball feels.
-- Defaults below target lighter "foam" flight: softer mass, stronger throw, Magnus + anti-gravity.

--!strict

local DodgeballConfig = {
	-- Pickup: if the ball is moving slower than this (studs per second), touching it picks it up.
	PICKUP_MAX_SPEED = 15,

	-- Out: a thrown ball must be at least this fast when it hits someone.
	HIT_MIN_SPEED = 25,

	-- Out: only hits within this many seconds after a throw can eliminate someone.
	THROW_OUT_WINDOW_SECONDS = 3,

	-- While a throw can eliminate, keep the ball server-simulated so OUT uses real physics contact
	-- (Touched + GetTouchingParts), not client-owned prediction. Disable only if BallPhysics must stay client-owned.
	HIT_FORCE_SERVER_PHYSICS_DURING_THROW = true,

	-- Throw strength (impulse) at 100% power. Bigger = faster throws.
	-- DefaultThrow multiplies this by the aim power bar (0–1) from the client.
	THROW_IMPULSE = 150,

	-- === Aim + power charge (hold throw button while aiming) ===

	-- Seconds to charge from 0% to 100% power while you hold aim.
	AIM_POWER_CHARGE_SECONDS = 1,

	-- Longest you can aim before the ball auto-throws at your crosshair + current power.
	AIM_MAX_SECONDS = 4,

	-- === Ball hold before you start aiming ===

	-- After pickup, you must start aiming within this many seconds or the ball rolls away (not a throw).
	BALL_MAX_HOLD_SECONDS = 10,

	-- Penalty when max hold expires: cannot pick up balls for this long.
	HOLD_PENALTY_PICKUP_COOLDOWN_SECONDS = 3,

	-- Penalty walk/jump slow duration (server restores DEFAULT_WALK_SPEED after).
	HOLD_PENALTY_SLOW_SECONDS = 3,

	-- WalkSpeed while slowed (multiplier on DEFAULT_WALK_SPEED; 0.5 = half speed).
	HOLD_PENALTY_WALK_SPEED_MULTIPLIER = 0.5,

	-- Gentle roll speed when max hold forces a drop (cannot eliminate anyone).
	HOLD_ROLL_IMPULSE = 50,

	-- Voluntary drop (drop key): light nudge away from the carrier.
	VOLUNTARY_DROP_IMPULSE = 10,

	-- After voluntary drop, that player cannot pick up the same ball for this long (seconds).
	VOLUNTARY_DROP_SAME_BALL_COOLDOWN_SECONDS = 1,

	-- After releasing a throw or hold roll, thrower character parts skip ball collision this long (seconds).
	-- Uses PhysicsService collision groups (see DodgeballThrowerCollision). 0 disables.
	THROWER_BALL_NOCOLLIDE_SECONDS = 0.35,

	-- Where ball Parts live in Workspace (you build this folder).
	BALL_FOLDER_NAME = "Dodgeballs",

	-- CollectionService tag (add in Studio if you use tags).
	DODGEBALL_TAG = "Dodgeball",

	-- === Shared dodgeball Part (arena balls + lobby practice spawns) ===

	-- Sphere diameter in studs (DodgeballBallTemplate applies to arena balls on load and spawns lobby balls).
	BALL_DIAMETER = 2.5,

	-- Default Part name when a script creates a ball (studio-placed balls can use any name).
	BALL_PART_NAME = "Dodgeball",

	BALL_COLOR = Color3.fromRGB(220, 220, 220),
	BALL_MATERIAL = Enum.Material.Fabric,

	-- Optional custom mass/feel (nil or omit → Roblox default). All three must be numbers to apply.
	BALL_PHYSICAL_DENSITY = 0.3,
	BALL_PHYSICAL_FRICTION = 0.4,
	BALL_PHYSICAL_ELASTICITY = 0.75,

	-- === Vendored BallPhysics (ReplicatedStorage/BallPhysics + AutoSetup) ===

	-- CollectionService tag the library tracks (in addition to DODGEBALL_TAG / lobby tags).
	BALL_PHYSICS_TAG = "PhysicsBall",

	BALL_PHYSICS_MAGNUS_ENABLED = true,
	BALL_PHYSICS_MAGNUS_STRENGTH = 1.5,
	BALL_PHYSICS_MAGNUS_DEFAULT_DENSITY = 0.7,

	BALL_PHYSICS_KNUCKLE_ENABLED = true,
	BALL_PHYSICS_KNUCKLE_STRENGTH = 18,
	BALL_PHYSICS_KNUCKLE_TARGET_SPEED = 75,

	BALL_PHYSICS_ANGULAR_DAMPING_ENABLED = true,
	BALL_PHYSICS_ANGULAR_DAMPING_AIR_RATE = 0.65,
	BALL_PHYSICS_ANGULAR_DAMPING_GROUND_RATE = 1,

	BALL_PHYSICS_ANTIGRAVITY_ENABLED = true,
	BALL_PHYSICS_ANTIGRAVITY_FRACTION = 0.62,

	-- Upstream F3/F4 overlay scripts are not bundled; library debug flag only when upstream ships dev tools.
	BALL_PHYSICS_DEBUG_ENABLED = false,

	-- Side spin (rad/s) on aimed throws so Magnus can curve; scaled by throw power (0–1).
	THROW_SIDE_SPIN_RAD_PER_SEC = 22,

	-- Which throw module to use from ServerScriptService/throw/ (more abilities later).
	ACTIVE_THROW_PROFILE = "Default",

	-- RemoteEvent folder name (created by DodgeballService if missing).
	REMOTES_FOLDER_NAME = "DodgeballRemotes",

	-- Name of the throw RemoteEvent (client asks server to throw).
	THROW_REMOTE_NAME = "RequestThrow",

	-- Client asks server to release a held ball without throwing (drop key).
	DROP_REMOTE_NAME = "RequestDropBall",

	-- How far the ball sits from the hand while carried.
	CARRY_OFFSET = Vector3.new(0, 0, -1.5),

	-- After you throw, wait this long before you can pick up again (studs/s spam guard).
	PICKUP_COOLDOWN_SECONDS = 0.15,

	-- When true, warn in Output why a throw hit did not eliminate someone (for debugging).
	DEBUG_ELIMINATION = false,

	-- Temporary: tagged Output lines for BallPhysics wiring (see DodgeballBallPhysicsDebug.md).
	DEBUG_BALL_PHYSICS = false,

	-- === Round reset — change these to tune between-round pacing ===

	-- Team names must match Explorer → Teams (same as TeamAutoBalance).
	TEAM_NAMES = { "Red", "Blue" },

	-- Countdown after a team wins before the next round (0 = skip straight to reset).
	ROUND_INTERMISSION_SECONDS = 5,

	-- If everyone is OUT at once, wait this long then reset anyway (tie / chaos).
	ROUND_TIE_RESET_DELAY_SECONDS = 2,

	-- Folder under ReplicatedStorage — RoundService writes RoundState + RoundNumber here.
	ROUND_STATUS_FOLDER_NAME = "RoundStatus",

	-- Walk/jump restored when a round clears OUT (before LoadCharacter).
	DEFAULT_WALK_SPEED = 25,
	DEFAULT_JUMP_POWER = 50,

	-- If a stray character still appears while OUT mid-match, "destroy" removes it (default).
	-- "lobby" teleports to LobbySpawn as sideline spectator (still IsOut, no throw) until round reset.
	OUT_STRAY_RESPAWN_FALLBACK = "destroy",

	-- === Lobby + match format ===

	-- Seconds to wait in lobby when 2+ players before a match starts (paused / reset if only 1 player).
	LOBBY_COUNTDOWN_SECONDS = 30,

	-- Round wins needed to win the whole match (then back to lobby).
	MATCH_POINTS_TO_WIN = 3,

	-- Lobby spawn wiring (you place this SpawnLocation — not where to build):
	-- Option A: rename a SpawnLocation to this exact name and set TeamColor Neutral / AllowTeamChangeOnTouch off.
	LOBBY_SPAWN_NAME = "LobbySpawn",
	-- Option B: tag a SpawnLocation with CollectionService (leave empty string to use name only).
	LOBBY_SPAWN_TAG = "",

	-- Lobby opt-in: default true on first join only; explicit false persists until toggle or re-join.
	JOIN_NEXT_MATCH_ATTR = "JoinNextMatch",
	SET_JOIN_NEXT_MATCH_REMOTE_NAME = "SetJoinNextMatch",

	-- === Lobby practice balls (waiting area — no OUT / damage) ===

	-- Workspace folder for script-spawned lobby balls (created if missing).
	LOBBY_BALL_FOLDER_NAME = "LobbyPracticeBalls",

	-- CollectionService tag on each lobby practice ball Part.
	LOBBY_PRACTICE_BALL_TAG = "LobbyPracticeBall",

	-- Tag spawn volume Parts/Models (multiple). Random spawn point inside each volume’s bounds.
	LOBBY_BALL_SPAWN_VOLUME_TAG = "LobbyBallSpawnVolume",

	-- Optional: tag Parts/Models that are off-limits (arena / match zone). Ball entering → instant recover + respawn in lobby.
	LOBBY_BALL_EXCLUDE_ZONE_TAG = "LobbyBallExcludeZone",

	-- Default min/max per spawn volume (override with attributes LobbyBallMin / LobbyBallMax on a volume).
	LOBBY_BALL_MIN_PER_AREA = 2,
	LOBBY_BALL_MAX_PER_AREA = 5,

	-- Seconds a lobby ball may sit idle (not held, roughly still) before delete + respawn in its area.
	LOBBY_BALL_IDLE_TIMEOUT_SECONDS = 45,

	-- Server maintenance tick for idle/bounds/count checks. Minimum recommended: 5–10s (do not run every frame).
	LOBBY_BALL_MAINTENANCE_INTERVAL_SECONDS = 8,

	-- Player/ball attribute marking lobby practice (safety rules — not arena OUT logic).
	LOBBY_PRACTICE_BALL_ATTR = "IsLobbyPracticeBall",
}

return DodgeballConfig
