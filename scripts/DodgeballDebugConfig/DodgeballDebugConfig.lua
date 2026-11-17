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
}

return DodgeballDebugConfig
