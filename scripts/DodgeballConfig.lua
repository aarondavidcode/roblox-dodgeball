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

	-- Throw strength (impulse). Bigger = faster throws.
	THROW_IMPULSE = 80,

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
}

return DodgeballConfig