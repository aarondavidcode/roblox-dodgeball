-- Studio setup: BallVisualEffectRegistry.md
-- Paste as ModuleScript BallVisualEffectRegistry under StarterPlayer → StarterPlayerScripts → ballVisualEffects.
-- Maps effect ids (from DodgeballConfig / player attributes) to effect modules.

--!strict

local BallVisualEffectRegistry = {}

export type EffectShellTunables = {
	-- Shell diameter = max(ball.Size) × diameterScale (BallVisualEffectShell).
	diameterScale: number,
}

export type EffectContext = {
	hitMinSpeed: number,
	speedGlowHysteresisFraction: number,
	-- Resolved each frame by DodgeballBallVisualEffectsClient (see BallVisualEffectColors).
	effectColor: Color3,
	spectatorColor: Color3,
	throwerUserId: number?,
	teamName: string?,
	-- Per-effect shell scale for the active effect on this ball (see DodgeballBallVisualEffectsConfig).
	shell: EffectShellTunables,
}

export type BallVisualEffectModule = {
	id: string,
	attach: (ball: BasePart, context: EffectContext) -> (),
	detach: (ball: BasePart) -> (),
	step: (ball: BasePart, context: EffectContext) -> (),
}

local byId: { [string]: BallVisualEffectModule } = {}

function BallVisualEffectRegistry.register(module: BallVisualEffectModule)
	if typeof(module.id) ~= "string" or module.id == "" then
		error("[BallVisualEffectRegistry] effect module missing id")
	end
	byId[module.id] = module
end

function BallVisualEffectRegistry.get(id: string): BallVisualEffectModule?
	return byId[id]
end

function BallVisualEffectRegistry.resolve(id: string, fallbackId: string): BallVisualEffectModule?
	local module = byId[id]
	if module then
		return module
	end
	return byId[fallbackId]
end

function BallVisualEffectRegistry.allIds(): { string }
	local ids = {}
	for effectId in byId do
		table.insert(ids, effectId)
	end
	table.sort(ids)
	return ids
end

return BallVisualEffectRegistry
