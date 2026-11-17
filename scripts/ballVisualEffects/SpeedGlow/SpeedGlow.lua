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
	fillTransparency: number,
	outlineTransparency: number,
	depthMode: string,
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
local RemoteDefaults = require(script.Parent:WaitForChild("BallVisualEffectRemoteDefaults"))

local function resolveSpeedGlow(context: Registry.EffectContext): Registry.SpeedGlowTunables
	local sg = context.speedGlow
	local fillT = RemoteDefaults.SPEED_GLOW_FILL_TRANSPARENCY
	local outlineT = RemoteDefaults.SPEED_GLOW_OUTLINE_TRANSPARENCY
	local minLum = RemoteDefaults.SPEED_GLOW_MIN_OUTLINE_LUMINANCE
	local paleOutline = RemoteDefaults.SPEED_GLOW_SPECTATOR_OUTLINE_COLOR
	if sg then
		if typeof(sg.fillTransparency) == "number" then
			fillT = sg.fillTransparency
		end
		if typeof(sg.outlineTransparency) == "number" then
			outlineT = sg.outlineTransparency
		end
		if typeof(sg.minOutlineLuminance) == "number" then
			minLum = sg.minOutlineLuminance
		end
		if typeof(sg.spectatorOutlineColor) == "Color3" then
			paleOutline = sg.spectatorOutlineColor
		end
	end
	return {
		fillTransparency = fillT,
		outlineTransparency = outlineT,
		minOutlineLuminance = minLum,
		spectatorOutlineColor = paleOutline,
	}
end

local function applyColors(state: State, context: Registry.EffectContext, glowing: boolean)
	local speedGlow = resolveSpeedGlow(context)
	local glowOpts: BallVisualEffectColors.GlowColorOptions = {
		minOutlineLuminance = speedGlow.minOutlineLuminance,
		paleOutline = speedGlow.spectatorOutlineColor,
	}
	local fill, outline = BallVisualEffectColors.colorsForGlow(context.effectColor, glowOpts)
	state.highlight.FillColor = fill
	state.highlight.OutlineColor = outline
	if glowing then
		state.highlight.FillTransparency = speedGlow.fillTransparency
		state.highlight.OutlineTransparency = speedGlow.outlineTransparency
	end
end

local function ensureHighlightOnBall(state: State, ball: BasePart)
	state.highlight.Adornee = ball
	state.highlight.Parent = ball
	state.adornee = ball
end

local function syncShell(state: State, ball: BasePart, context: Registry.EffectContext, glowing: boolean)
	local scale = context.shell.diameterScale
	local shell = state.shell
	if shell and shell.part.Parent then
		shell.setDiameterScale(scale)
		shell.setGlowActive(glowing)
		ensureHighlightOnBall(state, ball)
		return
	end

	if shell then
		shell.destroy()
		state.shell = nil
	end

	local created = BallVisualEffectShell.create(ball, SpeedGlow.id, scale)
	if created then
		state.shell = created
		created.setGlowActive(glowing)
	end
	ensureHighlightOnBall(state, ball)
end

local function createState(ball: BasePart, context: Registry.EffectContext): State
	local highlight = Instance.new("Highlight")
	highlight.Name = "SpeedGlow"
	highlight.FillColor = Color3.new(1, 1, 1)
	highlight.OutlineColor = Color3.new(1, 1, 1)
	highlight.FillTransparency = 1
	highlight.OutlineTransparency = 1
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
	syncShell(state, ball, context, false)
	applyColors(state, context, false)
	return state
end

function SpeedGlow.attach(ball: BasePart, context: Registry.EffectContext)
	local existing = stateByBall[ball]
	if existing then
		syncShell(existing, ball, context, existing.glowing)
		applyColors(existing, context, existing.glowing)
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

	local speed = ball.AssemblyLinearVelocity.Magnitude
	local onThreshold = context.hitMinSpeed
	local offThreshold = onThreshold * context.speedGlowHysteresisFraction

	local shouldGlow: boolean
	if state.glowing then
		shouldGlow = speed >= offThreshold
	else
		shouldGlow = speed >= onThreshold
	end

	syncShell(state, ball, context, shouldGlow)
	applyColors(state, context, shouldGlow)
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
		fillTransparency = if typeof(state.highlight.FillTransparency) == "number"
			then state.highlight.FillTransparency
			else 1,
		outlineTransparency = if typeof(state.highlight.OutlineTransparency) == "number"
			then state.highlight.OutlineTransparency
			else 1,
		depthMode = tostring(state.highlight.DepthMode),
	}
end

return SpeedGlow
