-- Studio setup: SpeedGlow.md
-- Client-only subtle team-colored aura on dodgeballs when speed >= HIT_MIN_SPEED (hysteresis off threshold).

--!strict

local SpeedGlow = {}

SpeedGlow.id = "SpeedGlow"

export type DebugSnapshot = {
	glowing: boolean,
	shouldGlow: boolean,
	speed: number,
	hitMinSpeed: number,
	offThreshold: number,
	emitterEnabled: boolean,
	highlightEnabled: boolean,
	shellActive: boolean,
	held: boolean,
	inThrowWindow: boolean,
	particleRate: number,
	particleSize: number,
}

type ShellHandle = BallVisualEffectShell.ShellHandle

type State = {
	highlight: Highlight,
	emitter: ParticleEmitter,
	shell: ShellHandle?,
	lastSpeed: number,
	glowing: boolean,
}

local stateByBall: { [BasePart]: State } = {}

local Registry = require(script.Parent:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(script.Parent:WaitForChild("BallVisualEffectColors"))
local BallVisualEffectShell = require(script.Parent:WaitForChild("BallVisualEffectShell"))
local RemoteDefaults = require(script.Parent:WaitForChild("BallVisualEffectRemoteDefaults"))

local function ballRadius(ball: BasePart): number
	return math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * 0.5
end

local function resolveSpeedGlow(context: Registry.EffectContext): Registry.SpeedGlowTunables
	local sg = context.speedGlow
	local defaults = {
		particleRate = RemoteDefaults.SPEED_GLOW_PARTICLE_RATE,
		particleSizeScale = RemoteDefaults.SPEED_GLOW_PARTICLE_SIZE_SCALE,
		particleLightEmission = RemoteDefaults.SPEED_GLOW_PARTICLE_LIGHT_EMISSION,
		particleTransparency = RemoteDefaults.SPEED_GLOW_PARTICLE_TRANSPARENCY,
		minOutlineLuminance = RemoteDefaults.SPEED_GLOW_MIN_OUTLINE_LUMINANCE,
		spectatorOutlineColor = RemoteDefaults.SPEED_GLOW_SPECTATOR_OUTLINE_COLOR,
	}
	if not sg then
		return defaults
	end
	return {
		particleRate = if typeof(sg.particleRate) == "number" then sg.particleRate else defaults.particleRate,
		particleSizeScale = if typeof(sg.particleSizeScale) == "number"
			then sg.particleSizeScale
			else defaults.particleSizeScale,
		particleLightEmission = if typeof(sg.particleLightEmission) == "number"
			then sg.particleLightEmission
			else defaults.particleLightEmission,
		particleTransparency = if typeof(sg.particleTransparency) == "number"
			then sg.particleTransparency
			else defaults.particleTransparency,
		minOutlineLuminance = if typeof(sg.minOutlineLuminance) == "number"
			then sg.minOutlineLuminance
			else defaults.minOutlineLuminance,
		spectatorOutlineColor = if typeof(sg.spectatorOutlineColor) == "Color3"
			then sg.spectatorOutlineColor
			else defaults.spectatorOutlineColor,
	}
end

local function throwOutWindowSeconds(windowSeconds: number): number
	if typeof(windowSeconds) ~= "number" or windowSeconds <= 0 then
		return 3
	end
	return windowSeconds
end

local function isWithinThrowOutWindow(ball: BasePart, windowSeconds: number): boolean
	local throwTime = ball:GetAttribute("LastThrowTime")
	if typeof(throwTime) ~= "number" or throwTime <= 0 then
		return false
	end
	local elapsed = workspace:GetServerTimeNow() - throwTime
	return elapsed >= 0 and elapsed <= throwOutWindowSeconds(windowSeconds)
end

-- Client physics/replication can under-report speed during a live throw; server stores LastThrowSpeed.
local function isBallHeldByPlayer(ball: BasePart): boolean
	local holderId = ball:GetAttribute("HolderUserId")
	return typeof(holderId) == "number" and holderId > 0
end

local function resolveGlowSpeed(ball: BasePart, context: Registry.EffectContext): number
	local measured = ball.AssemblyLinearVelocity.Magnitude
	local threshold = context.hitMinSpeed
	if measured >= threshold then
		return measured
	end
	local lastThrow = ball:GetAttribute("LastThrowSpeed")
	if typeof(lastThrow) ~= "number" or lastThrow < threshold then
		return measured
	end
	if not isWithinThrowOutWindow(ball, context.throwOutWindowSeconds) then
		return measured
	end
	return lastThrow
end

local function glowColorsForContext(context: Registry.EffectContext, tunables: Registry.SpeedGlowTunables): (Color3, Color3)
	local glowOpts: BallVisualEffectColors.GlowColorOptions = {
		minOutlineLuminance = tunables.minOutlineLuminance,
		paleOutline = tunables.spectatorOutlineColor,
	}
	return BallVisualEffectColors.colorsForGlow(context.effectColor, glowOpts)
end

local function particleColorForContext(context: Registry.EffectContext, tunables: Registry.SpeedGlowTunables): Color3
	local fill, outline = glowColorsForContext(context, tunables)
	return fill:Lerp(outline, 0.35)
end

local function applyGlowAppearance(state: State, context: Registry.EffectContext)
	local tunables = resolveSpeedGlow(context)
	local ball = state.highlight.Adornee :: BasePart
	local active = state.glowing and not isBallHeldByPlayer(ball)

	local fill, outline = glowColorsForContext(context, tunables)
	state.highlight.FillColor = fill
	state.highlight.OutlineColor = outline
	state.highlight.FillTransparency = 0.9
	state.highlight.OutlineTransparency = if active then 0.15 else 1
	state.highlight.Enabled = active

	if state.shell then
		state.shell.part.Color = outline
		state.shell.setDiameterScale(context.shell.diameterScale)
		state.shell.setGlowActive(active)
		if active then
			state.shell.part.Transparency = 0.78
		end
	end

	local diameter = ballRadius(ball) * 2
	local shellScale = context.shell.diameterScale
	if shellScale <= 0 then
		shellScale = 1
	end
	local particleSize = diameter * shellScale * tunables.particleSizeScale
	if particleSize < 0.05 then
		particleSize = 0.05
	end

	local color = particleColorForContext(context, tunables)
	state.emitter.Color = ColorSequence.new(color)
	state.emitter.LightEmission = tunables.particleLightEmission
	local coreTrans = math.clamp(tunables.particleTransparency, 0, 1)
	state.emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, particleSize),
		NumberSequenceKeypoint.new(0.65, particleSize * 0.55),
		NumberSequenceKeypoint.new(1, particleSize * 0.2),
	})
	state.emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, coreTrans),
		NumberSequenceKeypoint.new(0.5, math.clamp(coreTrans + 0.12, 0, 1)),
		NumberSequenceKeypoint.new(1, 1),
	})
	state.emitter.Rate = math.max(0, tunables.particleRate)
	state.emitter.Enabled = active and state.emitter.Rate > 0
end

local function updateGlowFromSpeed(state: State, speed: number, context: Registry.EffectContext)
	local onThreshold = context.hitMinSpeed
	local offThreshold = onThreshold * context.speedGlowHysteresisFraction
	if state.glowing then
		if speed < offThreshold then
			state.glowing = false
		end
	elseif speed >= onThreshold then
		state.glowing = true
	end
end

local function createState(ball: BasePart, context: Registry.EffectContext): State
	local shellScale = context.shell.diameterScale
	if shellScale <= 0 then
		shellScale = RemoteDefaults.SPEED_GLOW_SHELL_DIAMETER_SCALE
	end

	local highlight = Instance.new("Highlight")
	highlight.Name = "SpeedGlowHighlight"
	highlight.Adornee = ball
	highlight.DepthMode = Enum.HighlightDepthMode.Occluded
	highlight.Enabled = false
	highlight.Parent = ball

	-- ParticleEmitters parented under Attachments often fail to render (Roblox engine quirk); parent to the Part.
	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SpeedGlowParticles"
	emitter.Texture = "rbxassetid://243660364"
	emitter.Lifetime = NumberRange.new(0.45, 0.85)
	emitter.Speed = NumberRange.new(0.2, 0.55)
	emitter.SpreadAngle = Vector2.new(22, 22)
	emitter.Shape = Enum.ParticleEmitterShape.Sphere
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	emitter.ShapePartial = 1
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.LightInfluence = 0.1
	emitter.LockedToPart = true
	emitter.Drag = 1.5
	emitter.RotSpeed = NumberRange.new(-12, 12)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.Rate = 0
	emitter.Enabled = false
	emitter.Parent = ball

	local shell = BallVisualEffectShell.create(ball, "SpeedGlow", shellScale)

	local state: State = {
		highlight = highlight,
		emitter = emitter,
		shell = shell,
		lastSpeed = 0,
		glowing = false,
	}
	applyGlowAppearance(state, context)
	return state
end

local function refreshGlowState(state: State, ball: BasePart, context: Registry.EffectContext)
	state.lastSpeed = resolveGlowSpeed(ball, context)
	local inWindow = isWithinThrowOutWindow(ball, context.throwOutWindowSeconds)
	if isBallHeldByPlayer(ball) or not inWindow then
		state.glowing = false
	else
		updateGlowFromSpeed(state, state.lastSpeed, context)
	end
end

function SpeedGlow.attach(ball: BasePart, context: Registry.EffectContext)
	local existing = stateByBall[ball]
	if existing then
		refreshGlowState(existing, ball, context)
		applyGlowAppearance(existing, context)
		return
	end
	local state = createState(ball, context)
	refreshGlowState(state, ball, context)
	applyGlowAppearance(state, context)
	stateByBall[ball] = state
end

function SpeedGlow.detach(ball: BasePart)
	local state = stateByBall[ball]
	if not state then
		return
	end
	state.highlight:Destroy()
	state.emitter:Destroy()
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

	refreshGlowState(state, ball, context)
	applyGlowAppearance(state, context)
end

function SpeedGlow.getDebugSnapshot(ball: BasePart, context: Registry.EffectContext): DebugSnapshot?
	local state = stateByBall[ball]
	if not state then
		return nil
	end
	local onThreshold = context.hitMinSpeed
	local offThreshold = onThreshold * context.speedGlowHysteresisFraction
	local sizeKey = state.emitter.Size.Keypoints[1]
	local particleSize = if sizeKey then sizeKey.Value else 0
	local shouldGlow = state.glowing
	return {
		glowing = state.glowing,
		shouldGlow = shouldGlow,
		speed = state.lastSpeed,
		hitMinSpeed = onThreshold,
		offThreshold = offThreshold,
		emitterEnabled = state.emitter.Enabled,
		highlightEnabled = state.highlight.Enabled,
		shellActive = if state.shell then state.shell.part.Transparency < 1 else false,
		particleRate = state.emitter.Rate,
		particleSize = particleSize,
		held = isBallHeldByPlayer(ball),
		inThrowWindow = isWithinThrowOutWindow(ball, context.throwOutWindowSeconds),
	}
end

return SpeedGlow