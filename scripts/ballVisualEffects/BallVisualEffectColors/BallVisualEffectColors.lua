-- Studio setup: BallVisualEffectColors.md
-- Shared client helper: resolve EffectContext colors from thrower team (LastThrowerUserId) or spectator fallback.
-- Future effect modules should use context.effectColor — do not duplicate team lookup here unless extending rules.

--!strict

local Players = game:GetService("Players")

local BallVisualEffectColors = {}

export type ColorResolution = {
	effectColor: Color3,
	throwerUserId: number?,
	teamName: string?,
}

function BallVisualEffectColors.outlineFromFill(fill: Color3): Color3
	return Color3.new(math.clamp(fill.R + 0.15, 0, 1), math.clamp(fill.G + 0.15, 0, 1), math.clamp(fill.B + 0.15, 0, 1))
end

function BallVisualEffectColors.resolveForBall(ball: BasePart, spectatorColor: Color3): ColorResolution
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwerId) ~= "number" or throwerId <= 0 then
		return {
			effectColor = spectatorColor,
			throwerUserId = nil,
			teamName = nil,
		}
	end

	local thrower = Players:GetPlayerByUserId(throwerId)
	if not thrower then
		return {
			effectColor = spectatorColor,
			throwerUserId = throwerId,
			teamName = nil,
		}
	end

	local team = thrower.Team
	if not team then
		return {
			effectColor = spectatorColor,
			throwerUserId = throwerId,
			teamName = nil,
		}
	end

	return {
		effectColor = team.TeamColor.Color,
		throwerUserId = throwerId,
		teamName = team.Name,
	}
end

return BallVisualEffectColors
