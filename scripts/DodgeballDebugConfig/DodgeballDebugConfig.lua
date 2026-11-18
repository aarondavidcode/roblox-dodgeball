-- Studio setup: DodgeballDebugConfig.md
-- Paste as ModuleScript DodgeballDebugConfig under ServerScriptService.
-- Diagnostics only — keep off in published places unless you are troubleshooting.

--!strict

local DodgeballDebugConfig = {
	-- Extra Output when a throw hit does not eliminate someone (DodgeballService).
	DEBUG_ELIMINATION = false,

	-- [DodgeballBallPhysicsDebug] integration Output; mirrored on DodgeballRemotes for clients.
	DEBUG_BALL_PHYSICS = false,

	-- Enables BallPhysics library Config.debug (upstream dev overlays not vendored here).
	BALL_PHYSICS_DEBUG_ENABLED = false,

	-- [DodgeballBallVisualEffectsDebug] throw samples for SpeedGlow / client VFX; mirrored on DodgeballRemotes.
	DEBUG_BALL_VISUAL_EFFECTS = false,

	-- Studio: one human can start InMatch via /testmatch (DodgeballSinglePlayerTest + test NPCs). Keep false when publishing.
	SINGLE_PLAYER_TESTING = false,
}

return DodgeballDebugConfig
