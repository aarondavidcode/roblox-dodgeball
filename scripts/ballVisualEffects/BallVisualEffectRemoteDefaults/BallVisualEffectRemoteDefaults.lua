-- Studio setup: BallVisualEffectRemoteDefaults.md
-- Defaults must match DodgeballBallVisualEffectsConfig (client cannot require ServerScriptService).

--!strict

local BallVisualEffectRemoteDefaults = {
	DEFAULT_BALL_VISUAL_EFFECT = "SpeedGlow",
	SPEED_GLOW_HYSTERESIS_FRACTION = 0.92,
	SPEED_GLOW_SHELL_DIAMETER_SCALE = 1.4,
	SPEED_GLOW_FILL_TRANSPARENCY = 0.55,
	SPEED_GLOW_OUTLINE_TRANSPARENCY = 0.12,
	SPEED_GLOW_MIN_OUTLINE_LUMINANCE = 0.4,
	SPEED_GLOW_SPECTATOR_OUTLINE_COLOR = Color3.fromRGB(200, 220, 255),
	BALL_VISUAL_EFFECT_SPECTATOR_COLOR = Color3.fromRGB(255, 255, 255),
}

return BallVisualEffectRemoteDefaults
