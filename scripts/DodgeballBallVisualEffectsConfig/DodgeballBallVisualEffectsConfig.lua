-- Studio setup: DodgeballBallVisualEffectsConfig.md
-- Paste as ModuleScript DodgeballBallVisualEffectsConfig under ServerScriptService.
-- Client ball VFX: DodgeballService mirrors keys on ReplicatedStorage/DodgeballRemotes.

--!strict

local DodgeballBallVisualEffectsConfig = {
	-- Registry id for balls with no per-ball / per-thrower override.
	DEFAULT_BALL_VISUAL_EFFECT = "SpeedGlow",

	-- Future player cosmetics: attribute on Player (settings UI not wired yet).
	BALL_VISUAL_EFFECT_PLAYER_ATTR = "BallVisualEffect",

	-- Optional override on the ball Part (e.g. copied from thrower when released).
	BALL_VISUAL_EFFECT_BALL_ATTR = "BallVisualEffectId",

	-- Future RemoteFunction under DodgeballRemotes (server stub not created yet).
	SET_BALL_VISUAL_EFFECT_REMOTE_NAME = "SetBallVisualEffect",

	-- SpeedGlow disables below HIT_MIN_SPEED * this (reduces threshold flicker).
	SPEED_GLOW_HYSTERESIS_FRACTION = 0.92,

	-- SpeedGlow client shell: Highlight adorns a welded transparent sphere sized ballDiameter × this (spheres only).
	SPEED_GLOW_SHELL_DIAMETER_SCALE = 1.4,

	-- SpeedGlow Highlight strength while glowing (0 = opaque, 1 = invisible).
	SPEED_GLOW_FILL_TRANSPARENCY = 0.55,
	SPEED_GLOW_OUTLINE_TRANSPARENCY = 0.12,

	-- When fill is near-white on a pale ball, outline uses this rim color instead of fill+brighten.
	SPEED_GLOW_SPECTATOR_OUTLINE_COLOR = Color3.fromRGB(200, 220, 255),
	-- Relative luminance floor for outline (0–1). Boosts dark team colors on outline.
	SPEED_GLOW_MIN_OUTLINE_LUMINANCE = 0.4,

	-- Ball VFX when no thrower, thrower left, or thrower has no Team (lobby spectator practice).
	BALL_VISUAL_EFFECT_SPECTATOR_COLOR = Color3.fromRGB(255, 255, 255),

	-- Future per-effect shell scale: add BALL_VISUAL_EFFECT_<EFFECTID>_SHELL_DIAMETER_SCALE here
	-- (e.g. BALL_VISUAL_EFFECT_TRAILBURST_SHELL_DIAMETER_SCALE = 1.25), mirror in DodgeballService, read in DodgeballBallVisualEffectsClient.
}

return DodgeballBallVisualEffectsConfig
