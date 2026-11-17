-- Studio setup: DodgeballBallVisualEffectsClient.md
-- LocalScript: DodgeballBallVisualEffectsClient under StarterPlayer → StarterPlayerScripts
-- Applies registered ball visual effects (default SpeedGlow) to arena + lobby dodgeballs.

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local effectsFolder = script.Parent:WaitForChild("ballVisualEffects")
local Registry = require(effectsFolder:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(effectsFolder:WaitForChild("BallVisualEffectColors"))
local VisualEffectsDebug = require(effectsFolder:WaitForChild("DodgeballBallVisualEffectsDebug"))
local RemoteDefaults = require(effectsFolder:WaitForChild("BallVisualEffectRemoteDefaults"))
local SpeedGlow = require(effectsFolder:WaitForChild("SpeedGlow"))

Registry.register(SpeedGlow)

type EffectModule = Registry.BallVisualEffectModule

type TrackedEntry = {
	effectId: string,
	module: EffectModule,
}

local tracked: { [BasePart]: TrackedEntry } = {}
local throwDebugWired: { [BasePart]: boolean } = {}
local lastThrowSampleTime: { [BasePart]: number } = {}

local hitMinSpeed = 25
local speedGlowHysteresisFraction = RemoteDefaults.SPEED_GLOW_HYSTERESIS_FRACTION
local defaultEffectId = RemoteDefaults.DEFAULT_BALL_VISUAL_EFFECT
local dodgeballTag = "Dodgeball"
local lobbyPracticeTag = "LobbyPracticeBall"
local physicsBallTag = "PhysicsBall"
local ballEffectAttr = "BallVisualEffectId"
local playerEffectAttr = "BallVisualEffect"
local spectatorColor = RemoteDefaults.BALL_VISUAL_EFFECT_SPECTATOR_COLOR
local speedGlowShellDiameterScale = RemoteDefaults.SPEED_GLOW_SHELL_DIAMETER_SCALE
local speedGlowParticleRate = RemoteDefaults.SPEED_GLOW_PARTICLE_RATE
local speedGlowParticleSizeScale = RemoteDefaults.SPEED_GLOW_PARTICLE_SIZE_SCALE
local speedGlowParticleLightEmission = RemoteDefaults.SPEED_GLOW_PARTICLE_LIGHT_EMISSION
local speedGlowParticleTransparency = RemoteDefaults.SPEED_GLOW_PARTICLE_TRANSPARENCY
local speedGlowMinOutlineLuminance = RemoteDefaults.SPEED_GLOW_MIN_OUTLINE_LUMINANCE
local speedGlowSpectatorOutlineColor = RemoteDefaults.SPEED_GLOW_SPECTATOR_OUTLINE_COLOR

local remotes: Folder? = nil

local function readNumberAttr(name: string, fallback: number): number
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "number" and value > 0 then
			return value
		end
	end
	return fallback
end

local function readFractionAttr(name: string, fallback: number): number
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "number" and value > 0 and value <= 1 then
			return value
		end
	end
	return fallback
end

local function readOpacityAttr(name: string, fallback: number): number
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "number" and value >= 0 and value <= 1 then
			return value
		end
	end
	return fallback
end

local function readStringAttr(name: string, fallback: string): string
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "string" and value ~= "" then
			return value
		end
	end
	return fallback
end

local function readColor3Attr(name: string, fallback: Color3): Color3
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "Color3" then
			return value
		end
	end
	return fallback
end

local function ballTagsSummary(ball: BasePart): string
	return `dodgeball={CollectionService:HasTag(ball, dodgeballTag)} lobby={CollectionService:HasTag(
		ball,
		lobbyPracticeTag
	)} physics={CollectionService:HasTag(ball, physicsBallTag)}`
end

local logThrowSample: (BasePart, string) -> () = function() end

local function ensureThrowDebugWatch(ball: BasePart)
	if throwDebugWired[ball] then
		return
	end
	throwDebugWired[ball] = true
	ball:GetAttributeChangedSignal("LastThrowTime"):Connect(function()
		if not VisualEffectsDebug.isEnabled() then
			return
		end
		local throwTime = ball:GetAttribute("LastThrowTime")
		local throwerId = ball:GetAttribute("LastThrowerUserId")
		if typeof(throwTime) ~= "number" or throwTime <= 0 then
			return
		end
		if typeof(throwerId) ~= "number" or throwerId ~= player.UserId then
			return
		end
		if lastThrowSampleTime[ball] == throwTime then
			return
		end
		lastThrowSampleTime[ball] = throwTime
		logThrowSample(ball, "+0s")
		task.delay(0.35, function()
			if ball.Parent then
				logThrowSample(ball, "+0.35s")
			end
		end)
		task.delay(1, function()
			if ball.Parent then
				logThrowSample(ball, "+1s")
			end
		end)
	end)
end

local function logClientStart()
	if not VisualEffectsDebug.isEnabled() then
		return
	end
	local ids = table.concat(Registry.allIds(), ",")
	VisualEffectsDebug.log(`client start registry=[{ids}]`)
	if remotes then
		VisualEffectsDebug.log(`remotes {VisualEffectsDebug.snapshotRemotesAttrs(remotes)}`)
	else
		VisualEffectsDebug.warn("remotes folder missing at client start")
	end
end

local function hookRemoteTunables(folder: Folder)
	remotes = folder
	local function refresh()
		hitMinSpeed = readNumberAttr("HIT_MIN_SPEED", hitMinSpeed)
		speedGlowHysteresisFraction = readFractionAttr("SPEED_GLOW_HYSTERESIS_FRACTION", speedGlowHysteresisFraction)
		defaultEffectId = readStringAttr("DEFAULT_BALL_VISUAL_EFFECT", defaultEffectId)
		dodgeballTag = readStringAttr("DODGEBALL_TAG", dodgeballTag)
		lobbyPracticeTag = readStringAttr("LOBBY_PRACTICE_BALL_TAG", lobbyPracticeTag)
		physicsBallTag = readStringAttr("BALL_PHYSICS_TAG", physicsBallTag)
		ballEffectAttr = readStringAttr("BALL_VISUAL_EFFECT_BALL_ATTR", ballEffectAttr)
		playerEffectAttr = readStringAttr("BALL_VISUAL_EFFECT_PLAYER_ATTR", playerEffectAttr)
		spectatorColor = readColor3Attr("BALL_VISUAL_EFFECT_SPECTATOR_COLOR", spectatorColor)
		speedGlowShellDiameterScale = readNumberAttr("SPEED_GLOW_SHELL_DIAMETER_SCALE", speedGlowShellDiameterScale)
		speedGlowParticleRate = readNumberAttr("SPEED_GLOW_PARTICLE_RATE", speedGlowParticleRate)
		speedGlowParticleSizeScale = readFractionAttr("SPEED_GLOW_PARTICLE_SIZE_SCALE", speedGlowParticleSizeScale)
		speedGlowParticleLightEmission = readOpacityAttr(
			"SPEED_GLOW_PARTICLE_LIGHT_EMISSION",
			speedGlowParticleLightEmission
		)
		speedGlowParticleTransparency = readOpacityAttr(
			"SPEED_GLOW_PARTICLE_TRANSPARENCY",
			speedGlowParticleTransparency
		)
		speedGlowMinOutlineLuminance = readOpacityAttr("SPEED_GLOW_MIN_OUTLINE_LUMINANCE", speedGlowMinOutlineLuminance)
		speedGlowSpectatorOutlineColor =
			readColor3Attr("SPEED_GLOW_SPECTATOR_OUTLINE_COLOR", speedGlowSpectatorOutlineColor)
	end
	for _, name in
		{
			"HIT_MIN_SPEED",
			"SPEED_GLOW_HYSTERESIS_FRACTION",
			"DEFAULT_BALL_VISUAL_EFFECT",
			"DODGEBALL_TAG",
			"LOBBY_PRACTICE_BALL_TAG",
			"BALL_PHYSICS_TAG",
			"BALL_VISUAL_EFFECT_BALL_ATTR",
			"BALL_VISUAL_EFFECT_PLAYER_ATTR",
			"BALL_VISUAL_EFFECT_SPECTATOR_COLOR",
			"SPEED_GLOW_SHELL_DIAMETER_SCALE",
			"SPEED_GLOW_PARTICLE_RATE",
			"SPEED_GLOW_PARTICLE_SIZE_SCALE",
			"SPEED_GLOW_PARTICLE_LIGHT_EMISSION",
			"SPEED_GLOW_PARTICLE_TRANSPARENCY",
			"SPEED_GLOW_MIN_OUTLINE_LUMINANCE",
			"SPEED_GLOW_SPECTATOR_OUTLINE_COLOR",
			"DEBUG_BALL_VISUAL_EFFECTS",
		}
	do
		folder:GetAttributeChangedSignal(name):Connect(refresh)
	end
	folder:GetAttributeChangedSignal("DEBUG_BALL_VISUAL_EFFECTS"):Connect(function()
		if VisualEffectsDebug.isEnabled() then
			logClientStart()
		end
	end)
	refresh()
end

local function shellDiameterScaleForEffect(effectId: string): number
	if effectId == "SpeedGlow" then
		return speedGlowShellDiameterScale
	end
	return 1
end

local function makeContext(ball: BasePart, effectId: string): Registry.EffectContext
	local colorRes = BallVisualEffectColors.resolveForBall(ball, spectatorColor)
	local shellScale = shellDiameterScaleForEffect(effectId)
	if shellScale <= 0 then
		shellScale = 1.4
	end
	return {
		hitMinSpeed = hitMinSpeed,
		speedGlowHysteresisFraction = speedGlowHysteresisFraction,
		effectColor = colorRes.effectColor,
		spectatorColor = spectatorColor,
		throwerUserId = colorRes.throwerUserId,
		teamName = colorRes.teamName,
		shell = {
			diameterScale = shellScale,
		},
		speedGlow = {
			particleRate = readNumberAttr("SPEED_GLOW_PARTICLE_RATE", speedGlowParticleRate),
			particleSizeScale = readFractionAttr("SPEED_GLOW_PARTICLE_SIZE_SCALE", speedGlowParticleSizeScale),
			particleLightEmission = readOpacityAttr(
				"SPEED_GLOW_PARTICLE_LIGHT_EMISSION",
				speedGlowParticleLightEmission
			),
			particleTransparency = readOpacityAttr("SPEED_GLOW_PARTICLE_TRANSPARENCY", speedGlowParticleTransparency),
			minOutlineLuminance = readOpacityAttr("SPEED_GLOW_MIN_OUTLINE_LUMINANCE", speedGlowMinOutlineLuminance),
			spectatorOutlineColor = readColor3Attr(
				"SPEED_GLOW_SPECTATOR_OUTLINE_COLOR",
				speedGlowSpectatorOutlineColor
			),
		},
	}
end

local function isDodgeballPart(instance: Instance): boolean
	if not instance:IsA("BasePart") then
		return false
	end
	local ball = instance :: BasePart
	return CollectionService:HasTag(ball, dodgeballTag)
		or CollectionService:HasTag(ball, lobbyPracticeTag)
		or CollectionService:HasTag(ball, physicsBallTag)
end

local function resolveEffectId(ball: BasePart): string
	local onBall = ball:GetAttribute(ballEffectAttr)
	if typeof(onBall) == "string" and onBall ~= "" then
		return onBall
	end
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwerId) == "number" then
		local thrower = Players:GetPlayerByUserId(throwerId)
		if thrower then
			local fromPlayer = thrower:GetAttribute(playerEffectAttr)
			if typeof(fromPlayer) == "string" and fromPlayer ~= "" then
				return fromPlayer
			end
		end
	end
	return defaultEffectId
end

local function formatNum(value: number?, fallback: number): string
	if typeof(value) == "number" then
		return string.format("%.2f", value)
	end
	return string.format("%.2f", fallback)
end

logThrowSample = function(ball: BasePart, label: string)
	if not VisualEffectsDebug.isEnabled() then
		return
	end
	local entry = tracked[ball]
	local effectId = if entry then entry.effectId else resolveEffectId(ball)
	local context = makeContext(ball, effectId)
	local snap = SpeedGlow.getDebugSnapshot(ball, context)
	local colorRes = BallVisualEffectColors.resolveForBall(ball, spectatorColor)
	local teamLine = if colorRes.teamName
		then `team={colorRes.teamName} color={VisualEffectsDebug.formatColor3(colorRes.effectColor)}`
		else `spectator color={VisualEffectsDebug.formatColor3(colorRes.effectColor)}`
	local glowLine = if snap
		then `speed={formatNum(snap.speed, 0)} shouldGlow={snap.shouldGlow} emitter={snap.emitterEnabled} rate={formatNum(
			snap.particleRate,
			speedGlowParticleRate
		)} size={formatNum(snap.particleSize, 0)} attach={snap.attachmentName} hitMin={formatNum(
			snap.hitMinSpeed,
			hitMinSpeed
		)} offAt={formatNum(snap.offThreshold, hitMinSpeed)}`
		else "SpeedGlow state=nil (not attached)"
	VisualEffectsDebug.log(
		`throw sample {label} ball={ball.Name} tracked={entry ~= nil} tags={ballTagsSummary(ball)} effectId={effectId} tunables hitMin={hitMinSpeed} hysteresis={speedGlowHysteresisFraction} shellScale={speedGlowShellDiameterScale} {teamLine} {glowLine}`
	)
end

local function attachEffect(ball: BasePart)
	if tracked[ball] then
		return
	end
	local effectId = resolveEffectId(ball)
	local module = Registry.resolve(effectId, defaultEffectId)
	if not module then
		return
	end
	module.attach(ball, makeContext(ball, effectId))
	tracked[ball] = {
		effectId = effectId,
		module = module,
	}
	ensureThrowDebugWatch(ball)
end

local function detachEffect(ball: BasePart)
	local entry = tracked[ball]
	if not entry then
		return
	end
	entry.module.detach(ball)
	tracked[ball] = nil
end

local watchedTags: { string } = {}

local function refreshWatchedTagConnections()
	table.clear(watchedTags)
	table.insert(watchedTags, dodgeballTag)
	if lobbyPracticeTag ~= dodgeballTag then
		table.insert(watchedTags, lobbyPracticeTag)
	end
	if physicsBallTag ~= dodgeballTag and physicsBallTag ~= lobbyPracticeTag then
		table.insert(watchedTags, physicsBallTag)
	end
end

local tagAddedConnections: { RBXScriptConnection } = {}
local tagRemovedConnections: { RBXScriptConnection } = {}

local function bindTagSignals()
	for _, conn in tagAddedConnections do
		conn:Disconnect()
	end
	for _, conn in tagRemovedConnections do
		conn:Disconnect()
	end
	table.clear(tagAddedConnections)
	table.clear(tagRemovedConnections)

	refreshWatchedTagConnections()

	for _, tag in watchedTags do
		table.insert(
			tagAddedConnections,
			CollectionService:GetInstanceAddedSignal(tag):Connect(function(instance)
				if isDodgeballPart(instance) then
					attachEffect(instance :: BasePart)
				end
			end)
		)
		table.insert(
			tagRemovedConnections,
			CollectionService:GetInstanceRemovedSignal(tag):Connect(function(instance)
				if instance:IsA("BasePart") then
					detachEffect(instance :: BasePart)
				end
			end)
		)
	end

	for _, tag in watchedTags do
		for _, instance in CollectionService:GetTagged(tag) do
			if isDodgeballPart(instance) then
				attachEffect(instance :: BasePart)
			end
		end
	end
end

local function onTunablesChanged()
	local previousTracked = tracked
	tracked = {}
	for ball, entry in previousTracked do
		entry.module.detach(ball)
	end
	bindTagSignals()
end

task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("DodgeballRemotes", 120)
	if folder:IsA("Folder") then
		hookRemoteTunables(folder)
		folder:GetAttributeChangedSignal("DODGEBALL_TAG"):Connect(onTunablesChanged)
		folder:GetAttributeChangedSignal("LOBBY_PRACTICE_BALL_TAG"):Connect(onTunablesChanged)
		folder:GetAttributeChangedSignal("BALL_PHYSICS_TAG"):Connect(onTunablesChanged)
		onTunablesChanged()
	else
		bindTagSignals()
	end
	logClientStart()
end)

RunService.Heartbeat:Connect(function()
	for ball, entry in tracked do
		local ok, err = pcall(function()
			if not ball.Parent then
				detachEffect(ball)
				return
			end

			local desiredId = resolveEffectId(ball)
			local context = makeContext(ball, desiredId)

			if desiredId ~= entry.effectId then
				entry.module.detach(ball)
				local module = Registry.resolve(desiredId, defaultEffectId)
				if not module then
					detachEffect(ball)
					return
				end
				module.attach(ball, context)
				tracked[ball] = { effectId = desiredId, module = module }
				entry = tracked[ball]
			end

			entry.module.step(ball, context)
		end)
		if not ok then
			warn(`[DodgeballBallVisualEffectsClient] step failed ball={ball.Name} err={err}`)
			detachEffect(ball)
		end
	end
end)

-- Extension: server may add RemoteFunction SET_BALL_VISUAL_EFFECT_REMOTE_NAME (DodgeballBallVisualEffectsConfig)
-- to validate player-chosen effect ids and set BALL_VISUAL_EFFECT_PLAYER_ATTR — not wired yet.
