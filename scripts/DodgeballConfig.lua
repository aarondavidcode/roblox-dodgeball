-- Paste this as a ModuleScript named DodgeballConfig under ServerScriptService.
-- Kids: change the numbers below to tune how dodgeball feels.

--!strict

local DodgeballConfig = {
	-- Pickup: if the ball is moving slower than this (studs per second), touching it picks it up.
	PICKUP_MAX_SPEED = 8,

	-- Out: a thrown ball must be at least this fast when it hits someone.
	HIT_MIN_SPEED = 25,

	-- Out: only hits within this many seconds after a throw can eliminate someone.
	THROW_OUT_WINDOW_SECONDS = 3,

	-- Throw strength (impulse) at 100% power. Bigger = faster throws.
	-- DefaultThrow multiplies this by the aim power bar (0–1) from the client.
	THROW_IMPULSE = 80,

	-- === Aim + power charge (hold throw button while aiming) ===

	-- Seconds to charge from 0% to 100% power while you hold aim.
	AIM_POWER_CHARGE_SECONDS = 1.25,

	-- Longest you can aim before the ball auto-throws at your crosshair + current power.
	AIM_MAX_SECONDS = 4,

	-- === Ball hold before you start aiming ===

	-- After pickup, you must start aiming within this many seconds or the ball rolls away (not a throw).
	BALL_MAX_HOLD_SECONDS = 5,

	-- Penalty when max hold expires: cannot pick up balls for this long.
	HOLD_PENALTY_PICKUP_COOLDOWN_SECONDS = 3,

	-- Penalty walk/jump slow duration (server restores DEFAULT_WALK_SPEED after).
	HOLD_PENALTY_SLOW_SECONDS = 3,

	-- WalkSpeed while slowed (multiplier on DEFAULT_WALK_SPEED; 0.5 = half speed).
	HOLD_PENALTY_WALK_SPEED_MULTIPLIER = 0.5,

	-- Gentle roll speed when max hold forces a drop (cannot eliminate anyone).
	HOLD_ROLL_IMPULSE = 12,

	-- Where ball Parts live in Workspace (kids build this folder).
	BALL_FOLDER_NAME = "Dodgeballs",

	-- CollectionService tag (add in Studio if you use tags).
	DODGEBALL_TAG = "Dodgeball",

	-- Which throw module to use from ServerScriptService/throw/ (more abilities later).
	ACTIVE_THROW_PROFILE = "Default",

	-- RemoteEvent folder name (created by DodgeballService if missing).
	REMOTES_FOLDER_NAME = "DodgeballRemotes",

	-- Name of the throw RemoteEvent (client asks server to throw).
	THROW_REMOTE_NAME = "RequestThrow",

	-- How far the ball sits from the hand while carried.
	CARRY_OFFSET = Vector3.new(0, 0, -1.5),

	-- After you throw, wait this long before you can pick up again (studs/s spam guard).
	PICKUP_COOLDOWN_SECONDS = 0.15,

	-- When true, warn in Output why a throw hit did not eliminate someone (for debugging).
	DEBUG_ELIMINATION = false,

	-- === Round reset (step 5) — change these to tune between-round pacing ===

	-- Team names must match Explorer → Teams (same as TeamAutoBalance).
	TEAM_NAMES = { "Red", "Blue" },

	-- Countdown after a team wins before the next round (0 = skip straight to reset).
	ROUND_INTERMISSION_SECONDS = 5,

	-- If everyone is OUT at once, wait this long then reset anyway (tie / chaos).
	ROUND_TIE_RESET_DELAY_SECONDS = 2,

	-- Folder under ReplicatedStorage — RoundService writes RoundState + RoundNumber here.
	ROUND_STATUS_FOLDER_NAME = "RoundStatus",

	-- Walk/jump restored when a round clears OUT (before LoadCharacter).
	DEFAULT_WALK_SPEED = 16,
	DEFAULT_JUMP_POWER = 50,

	-- If a stray character still appears while OUT mid-match, "destroy" removes it (default).
	-- "lobby" teleports to LobbySpawn as sideline spectator (still IsOut, no throw) until round reset.
	OUT_STRAY_RESPAWN_FALLBACK = "destroy",

	-- === Lobby + match format (step 6) ===

	-- Seconds to wait in lobby when 2+ players before a match starts (paused / reset if only 1 player).
	LOBBY_COUNTDOWN_SECONDS = 30,

	-- Round wins needed to win the whole match (then back to lobby).
	MATCH_POINTS_TO_WIN = 3,

	-- Lobby spawn wiring (kids place this SpawnLocation — not where to build):
	-- Option A: rename a SpawnLocation to this exact name and set TeamColor Neutral / AllowTeamChangeOnTouch off.
	LOBBY_SPAWN_NAME = "LobbySpawn",
	-- Option B: tag a SpawnLocation with CollectionService (leave empty string to use name only).
	LOBBY_SPAWN_TAG = "",

	-- Lobby opt-in: default true on first join only; explicit false persists until toggle or re-join.
	JOIN_NEXT_MATCH_ATTR = "JoinNextMatch",
	SET_JOIN_NEXT_MATCH_REMOTE_NAME = "SetJoinNextMatch",
}

return DodgeballConfig