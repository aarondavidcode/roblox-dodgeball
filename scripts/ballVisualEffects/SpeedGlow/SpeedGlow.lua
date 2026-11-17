-- Studio setup: SpeedGlow.md
-- Paste as ModuleScript SpeedGlow under StarterPlayer → StarterPlayerScripts → ballVisualEffects.
-- Faint highlight when the ball moves at or above HIT_MIN_SPEED (from replicated tunables).

--!strict

local SpeedGlow = {}

SpeedGlow.id = "SpeedGlow"

local BallVisualEffectShell = require(script.Parent:WaitForChild("BallVisualEffectShell"))

type ShellHandle = BallVisualEffectShell.ShellHandle

export type DebugSnapshot = {
	glowing: boolean,
	shouldGlow: boolean,
	speed: number,
	hitMinSpeed: number,
	offThreshold: number,
	highlightEnabled: boolean,
	adorneeName: string,
	shellExists: boolean,
	shellSize: string,
}

type State = {
	highlight: Highlight,
	adornee: BasePart,
	shell: ShellHandle?,
	glowing: boolean,
	lastShouldGlow: boolean,
	lastSpeed: number,
}

local stateByBall: { [BasePart]: State } = {}

local Registry = require(script.Parent:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(script.Parent:WaitForChild("BallVisualEffectColors"))

local function applyColors(state: State, context: Registry.EffectContext)
	state.highlight.FillColor = context.effectColor
	state.highlight.OutlineColor = BallVisualEffectColors.outlineFromFill(context.effectColor)
end

local function ensureHighlightOnAdornee(state: State, ball: BasePart, adornee: BasePart)
	state.highlight.Adornee = adornee
	state.highlight.Parent = ball
	state.adornee = adornee
end

local function syncShell(state: State, ball: BasePart, context: Registry.EffectContext)
	local scale = context.shell.diameterScale
	local shell = state.shell
	if shell and shell.part.Parent then
		shell.setDiameterScale(scale)
		ensureHighlightOnAdornee(state, ball, shell.part)
		return
	end

	if shell then
		shell.destroy()
		state.shell = nil
	end

	local created = BallVisualEffectShell.create(ball, SpeedGlow.id, scale)
	if created then
		state.shell = created
		ensureHighlightOnAdornee(state, ball, created.part)
	else
		ensureHighlightOnAdornee(state, ball, ball)
	end
end

local function createState(ball: BasePart, context: Registry.EffectContext): State
	local highlight = Instance.new("Highlight")
	highlight.Name = "SpeedGlow"
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 0.82
	highlight.OutlineTransparency = 0.45
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.Enabled = false

	local state: State = {
		highlight = highlight,
		adornee = ball,
		shell = nil,
		glowing = false,
		lastShouldGlow = false,
		lastSpeed = 0,
	}
	syncShell(state, ball, context)
	applyColors(state, context)
	return state
end

function SpeedGlow.attach(ball: BasePart, context: Registry.EffectContext)
	local existing = stateByBall[ball]
	if existing then
		syncShell(existing, ball, context)
		applyColors(existing, context)
		return
	end
	stateByBall[ball] = createState(ball, context)
end

function SpeedGlow.detach(ball: BasePart)
	local state = stateByBall[ball]
	if not state then
		return
	end
	state.highlight:Destroy()
	if state.shell then
		state.shell.destroy()
	end
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

	syncShell(state, ball, context)

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
	state.lastShouldGlow = shouldGlow
	state.lastSpeed = speed
	state.highlight.Enabled = shouldGlow
end

function SpeedGlow.getDebugSnapshot(ball: BasePart, context: Registry.EffectContext): DebugSnapshot?
	local state = stateByBall[ball]
	if not state then
		return nil
	end
	local onThreshold = context.hitMinSpeed
	local offThreshold = onThreshold * context.speedGlowHysteresisFraction
	local shellPart = state.shell and state.shell.part
	local shellSize = if shellPart then tostring(shellPart.Size) else "none"
	return {
		glowing = state.glowing,
		shouldGlow = state.lastShouldGlow,
		speed = state.lastSpeed,
		hitMinSpeed = onThreshold,
		offThreshold = offThreshold,
		highlightEnabled = state.highlight.Enabled,
		adorneeName = state.adornee.Name,
		shellExists = shellPart ~= nil and shellPart.Parent ~= nil,
		shellSize = shellSize,
	}
end

return SpeedGlow
