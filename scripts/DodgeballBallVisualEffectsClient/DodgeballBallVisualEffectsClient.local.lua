-- Studio setup: DodgeballBallVisualEffectsClient.md
-- LocalScript: DodgeballBallVisualEffectsClient under StarterPlayer → StarterPlayerScripts
-- Applies registered ball visual effects (default SpeedGlow) to arena + lobby dodgeballs.

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local effectsFolder = script.Parent:WaitForChild("ballVisualEffects")
local Registry = require(effectsFolder:WaitForChild("BallVisualEffectRegistry"))
local BallVisualEffectColors = require(effectsFolder:WaitForChild("BallVisualEffectColors"))
local SpeedGlow = require(effectsFolder:WaitForChild("SpeedGlow"))

Registry.register(SpeedGlow)

type EffectModule = Registry.BallVisualEffectModule

type TrackedEntry = {
	effectId: string,
	module: EffectModule,
}

local tracked: { [BasePart]: TrackedEntry } = {}

local hitMinSpeed = 25
local speedGlowHysteresisFraction = 0.92
local defaultEffectId = "SpeedGlow"
local dodgeballTag = "Dodgeball"
local lobbyPracticeTag = "LobbyPracticeBall"
local physicsBallTag = "PhysicsBall"
local ballEffectAttr = "BallVisualEffectId"
local playerEffectAttr = "BallVisualEffect"
local spectatorColor = Color3.fromRGB(255, 255, 255)
local speedGlowShellDiameterScale = 1.4

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

local function hookRemoteTunables(folder: Folder)
	remotes = folder
	local function refresh()
		hitMinSpeed = readNumberAttr("HIT_MIN_SPEED", hitMinSpeed)
		speedGlowHysteresisFraction = readNumberAttr("SPEED_GLOW_HYSTERESIS_FRACTION", speedGlowHysteresisFraction)
		defaultEffectId = readStringAttr("DEFAULT_BALL_VISUAL_EFFECT", defaultEffectId)
		dodgeballTag = readStringAttr("DODGEBALL_TAG", dodgeballTag)
		lobbyPracticeTag = readStringAttr("LOBBY_PRACTICE_BALL_TAG", lobbyPracticeTag)
		physicsBallTag = readStringAttr("BALL_PHYSICS_TAG", physicsBallTag)
		ballEffectAttr = readStringAttr("BALL_VISUAL_EFFECT_BALL_ATTR", ballEffectAttr)
		playerEffectAttr = readStringAttr("BALL_VISUAL_EFFECT_PLAYER_ATTR", playerEffectAttr)
		spectatorColor = readColor3Attr("BALL_VISUAL_EFFECT_SPECTATOR_COLOR", spectatorColor)
		speedGlowShellDiameterScale = readNumberAttr("SPEED_GLOW_SHELL_DIAMETER_SCALE", speedGlowShellDiameterScale)
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
		}
	do
		folder:GetAttributeChangedSignal(name):Connect(refresh)
	end
	refresh()
end

local function shellDiameterScaleForEffect(effectId: string): number
	if effectId == "SpeedGlow" then
		return speedGlowShellDiameterScale
	end
	-- Future: elseif effectId == "TrailBurst" then return readNumberAttr("BALL_VISUAL_EFFECT_TRAILBURST_SHELL_DIAMETER_SCALE", 1.25)
	return 1
end

local function makeContext(ball: BasePart, effectId: string): Registry.EffectContext
	local colorRes = BallVisualEffectColors.resolveForBall(ball, spectatorColor)
	return {
		hitMinSpeed = hitMinSpeed,
		speedGlowHysteresisFraction = speedGlowHysteresisFraction,
		effectColor = colorRes.effectColor,
		spectatorColor = spectatorColor,
		throwerUserId = colorRes.throwerUserId,
		teamName = colorRes.teamName,
		shell = {
			diameterScale = shellDiameterScaleForEffect(effectId),
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
	end
	bindTagSignals()
end)

RunService.Heartbeat:Connect(function()
	for ball, entry in tracked do
		if not ball.Parent then
			detachEffect(ball)
			continue
		end

		local desiredId = resolveEffectId(ball)
		local context = makeContext(ball, desiredId)

		if desiredId ~= entry.effectId then
			entry.module.detach(ball)
			local module = Registry.resolve(desiredId, defaultEffectId)
			if not module then
				detachEffect(ball)
				continue
			end
			module.attach(ball, context)
			tracked[ball] = { effectId = desiredId, module = module }
			entry = tracked[ball]
		end

		-- effectColor / teamName refresh every frame when LastThrowerUserId or Team changes.
		entry.module.step(ball, context)
	end
end)

-- Extension: server may add RemoteFunction SET_BALL_VISUAL_EFFECT_REMOTE_NAME (DodgeballBallVisualEffectsConfig)
-- to validate player-chosen effect ids and set BALL_VISUAL_EFFECT_PLAYER_ATTR — not wired yet.
