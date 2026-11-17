-- Studio setup: SpeedGlow.md
-- Client Particles on Attachment when speed >= HIT_MIN_SPEED (team/spectator color).

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
	particleRate: number,
	particleSize: number,
	attachmentName: string,
}

type State = {
	attachment: Attachment,
	emitter: ParticleEmitter,
	glowing: boolean,
	lastShouldGlow: boolean,
	lastSpeed: number,
}

local stateByBall: { [BasePart]: State } = {}

local Registry = require(script.Parent:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(script.Parent:WaitForChild("BallVisualEffectColors"))
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

local function particleColorForContext(context: Registry.EffectContext, tunables: Registry.SpeedGlowTunables): Color3
	local glowOpts: BallVisualEffectColors.GlowColorOptions = {
		minOutlineLuminance = tunables.minOutlineLuminance,
		paleOutline = tunables.spectatorOutlineColor,
	}
	local fill, _outline = BallVisualEffectColors.colorsForGlow(context.effectColor, glowOpts)
	return fill
end

local function applyEmitterAppearance(state: State, context: Registry.EffectContext, glowing: boolean)
	local tunables = resolveSpeedGlow(context)
	local diameter = ballRadius(state.attachment.Parent :: BasePart) * 2
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
	state.emitter.Size = NumberSequence.new(particleSize)
	local trans = tunables.particleTransparency
	state.emitter.Transparency = NumberSequence.new(trans)
	state.emitter.Rate = if glowing then math.max(0, tunables.particleRate) else 0
	state.emitter.Enabled = glowing
end

local function createState(ball: BasePart, context: Registry.EffectContext): State
	local attachment = Instance.new("Attachment")
	attachment.Name = "SpeedGlowAttachment"
	attachment.Position = Vector3.zero
	attachment.Parent = ball

	local emitter = Instance.new("ParticleEmitter")
	emitter.Name = "SpeedGlowParticles"
	emitter.Texture = "rbxassetid://241685484"
	emitter.Lifetime = NumberRange.new(0.15, 0.35)
	emitter.Speed = NumberRange.new(0.05, 0.4)
	emitter.SpreadAngle = Vector2.new(180, 180)
	emitter.Shape = Enum.ParticleEmitterShape.Sphere
	emitter.ShapeStyle = Enum.ParticleEmitterShapeStyle.Surface
	emitter.ShapePartial = 1
	emitter.Orientation = Enum.ParticleOrientation.FacingCamera
	emitter.LightInfluence = 0
	emitter.Drag = 0
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.ZOffset = 0.1
	emitter.Rate = 0
	emitter.Parent = attachment

	local state: State = {
		attachment = attachment,
		emitter = emitter,
		glowing = false,
		lastShouldGlow = false,
		lastSpeed = 0,
	}
	applyEmitterAppearance(state, context, false)
	return state
end

function SpeedGlow.attach(ball: BasePart, context: Registry.EffectContext)
	local existing = stateByBall[ball]
	if existing then
		applyEmitterAppearance(existing, context, existing.glowing)
		return
	end
	stateByBall[ball] = createState(ball, context)
end

function SpeedGlow.detach(ball: BasePart)
	local state = stateByBall[ball]
	if not state then
		return
	end
	state.emitter:Destroy()
	state.attachment:Destroy()
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

	if shouldGlow ~= state.glowing then
		applyEmitterAppearance(state, context, shouldGlow)
	elseif shouldGlow then
		applyEmitterAppearance(state, context, true)
	end

	state.glowing = shouldGlow
	state.lastShouldGlow = shouldGlow
	state.lastSpeed = speed
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
	return {
		glowing = state.glowing,
		shouldGlow = state.lastShouldGlow,
		speed = state.lastSpeed,
		hitMinSpeed = onThreshold,
		offThreshold = offThreshold,
		emitterEnabled = state.emitter.Enabled,
		particleRate = state.emitter.Rate,
		particleSize = particleSize,
		attachmentName = state.attachment.Name,
	}
end

return SpeedGlow
