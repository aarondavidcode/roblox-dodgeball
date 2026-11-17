-- Studio setup: SpeedGlow.md
-- Paste as ModuleScript SpeedGlow under StarterPlayer → StarterPlayerScripts → ballVisualEffects.
-- Faint highlight when the ball moves at or above HIT_MIN_SPEED (from replicated tunables).

--!strict

local SpeedGlow = {}

SpeedGlow.id = "SpeedGlow"

type State = {
	highlight: Highlight,
	glowing: boolean,
}

local stateByBall: { [BasePart]: State } = {}

local function getOrCreateState(ball: BasePart): State
	local existing = stateByBall[ball]
	if existing then
		return existing
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SpeedGlow"
	highlight.Adornee = ball
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.82
	highlight.OutlineTransparency = 0.45
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = ball

	local state: State = {
		highlight = highlight,
		glowing = false,
	}
	stateByBall[ball] = state
	return state
end

local Registry = require(script.Parent:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(script.Parent:WaitForChild("BallVisualEffectColors"))

local function applyColors(state: State, context: Registry.EffectContext)
	state.highlight.FillColor = context.effectColor
	state.highlight.OutlineColor = BallVisualEffectColors.outlineFromFill(context.effectColor)
end

function SpeedGlow.attach(ball: BasePart, context: Registry.EffectContext)
	local state = getOrCreateState(ball)
	applyColors(state, context)
end

function SpeedGlow.detach(ball: BasePart)
	local state = stateByBall[ball]
	if not state then
		return
	end
	state.highlight:Destroy()
	stateByBall[ball] = nil
end

function SpeedGlow.step(ball: BasePart, context: Registry.EffectContext)
	local state = stateByBall[ball]
	if not state then
		return
	end
	if not ball.Parent then
		SpeedGlow.detach(ball)
		return
	end

	local speed = ball.AssemblyLinearVelocity.Magnitude
	local onThreshold = context.hitMinSpeed
	local offThreshold = onThreshold * context.speedGlowHysteresisFraction

	local shouldGlow: boolean
	if state.glowing then
		shouldGlow = speed >= offThreshold
	else
		shouldGlow = speed >= onThreshold
	end

	applyColors(state, context)
	state.glowing = shouldGlow
	state.highlight.Enabled = shouldGlow
end

return SpeedGlow
