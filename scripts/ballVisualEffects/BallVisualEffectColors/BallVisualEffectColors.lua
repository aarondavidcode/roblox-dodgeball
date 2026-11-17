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

export type GlowColorOptions = {
	minOutlineLuminance: number,
	paleOutline: Color3,
}

local function relativeLuminance(color: Color3): number
	return 0.2126 * color.R + 0.7152 * color.G + 0.0722 * color.B
end

function BallVisualEffectColors.outlineFromFill(fill: Color3): Color3
	return Color3.new(math.clamp(fill.R + 0.15, 0, 1), math.clamp(fill.G + 0.15, 0, 1), math.clamp(fill.B + 0.15, 0, 1))
end

function BallVisualEffectColors.colorsForGlow(fill: Color3, options: GlowColorOptions): (Color3, Color3)
	local outline: Color3
	if relativeLuminance(fill) >= 0.82 then
		outline = options.paleOutline
	elseif relativeLuminance(fill) >= 0.65 then
		outline = options.paleOutline:Lerp(BallVisualEffectColors.outlineFromFill(fill), 0.45)
	else
		outline = BallVisualEffectColors.outlineFromFill(fill)
	end

	local minLum = options.minOutlineLuminance
	if relativeLuminance(outline) < minLum and minLum > 0 then
		local scale = minLum / math.max(relativeLuminance(outline), 1e-4)
		scale = math.min(scale, 2.5)
		outline = Color3.new(
			math.clamp(outline.R * scale, 0, 1),
			math.clamp(outline.G * scale, 0, 1),
			math.clamp(outline.B * scale, 0, 1)
		)
	end

	local glowFill = fill
	if relativeLuminance(fill) >= 0.92 then
		glowFill = Color3.new(0.92, 0.95, 1)
	end

	return glowFill, outline
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
