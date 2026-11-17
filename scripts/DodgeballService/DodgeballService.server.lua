-- Studio setup: DodgeballService.md
-- Paste as Script named DodgeballService under ServerScriptService.
-- Needs DodgeballConfig (ModuleScript), throw/DefaultThrow (ModuleScript), and Workspace/Dodgeballs.
--
-- Eliminations during a live throw use server Heartbeat + Spherecast sweeps between
-- frames (not .Touched). Fast throws can tunnel through avatars; Touched also fires late
-- with wrong velocity. .Touched remains only for slow rolling pickup when not throwing.

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))
local VisualEffectsConfig = require(ServerScriptService:WaitForChild("DodgeballBallVisualEffectsConfig"))
local DebugConfig = require(ServerScriptService:WaitForChild("DodgeballDebugConfig"))
local BallTemplate = require(ServerScriptService:WaitForChild("DodgeballBallTemplate"))
local ThrowerCollision = require(ServerScriptService:WaitForChild("DodgeballThrowerCollision"))
local BallPhysicsDebug = require(ServerScriptService:WaitForChild("DodgeballBallPhysicsDebug"))

-- Roblox only documents Players.CharacterAutoLoads (global). When false, the engine does not
-- auto-call LoadCharacter after death; RespawnTime (default 5s) applies only while global is true.
-- All joins and round resets use explicit LoadCharacter from LobbyService / RoundService.
Players.CharacterAutoLoads = false

local throwFolder = ServerScriptService:WaitForChild("throw")
local DefaultThrow = require(throwFolder:WaitForChild("DefaultThrow"))

type ThrowProfileModule = typeof(DefaultThrow)

local ACTIVE_PROFILE: ThrowProfileModule = DefaultThrow
if Config.ACTIVE_THROW_PROFILE ~= "Default" then
	local moduleScript = throwFolder:FindFirstChild(Config.ACTIVE_THROW_PROFILE)
	if moduleScript and moduleScript:IsA("ModuleScript") then
		ACTIVE_PROFILE = require(moduleScript) :: ThrowProfileModule
	else
		warn(`[DodgeballService] Throw profile {Config.ACTIVE_THROW_PROFILE} not found; using Default.`)
	end
end

local heldByPlayer: { [Player]: BasePart } = {}
local ballHeldConnection: { [BasePart]: RBXScriptConnection } = {}
local throwSweepWatch: { [BasePart]: RBXScriptConnection } = {}

local ATTR_HOLD_PENALTY_PICKUP_UNTIL = "HoldPenaltyPickupUntil"
local START_AIMING_REMOTE_NAME = "StartAiming"

local aimingBeforeThrow: { [Player]: boolean } = {}
local holdWatchToken: { [Player]: number } = {}
local holdPenaltySlowToken: { [Player]: number } = {}

local function debugElimination(message: string)
	if DebugConfig.DEBUG_ELIMINATION then
		warn(`[DodgeballService] {message}`)
	end
end

local function ballCastRadius(ball: BasePart): number
	return math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * 0.5
end

local function isLiveThrow(ball: BasePart): boolean
	local throwTime = ball:GetAttribute("LastThrowTime")
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwTime) ~= "number" or typeof(throwerId) ~= "number" then
		return false
	end
	if throwTime <= 0 then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now - throwTime > Config.THROW_OUT_WINDOW_SECONDS then
		return false
	end
	return ball:GetAttribute("InThrowWindow") == true
end

local function stopThrowSweep(ball: BasePart)
	local conn = throwSweepWatch[ball]
	if conn then
		conn:Disconnect()
		throwSweepWatch[ball] = nil
	end
end

local function playerFromPart(part: BasePart): Player?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local dropBallFromPlayer: (Player) -> ()
local tryEliminateOnHit: (BasePart, Player, boolean) -> boolean

local function startThrowSweep(ball: BasePart)
	stopThrowSweep(ball)
	local lastPos = ball.Position
	local radius = ballCastRadius(ball)

	throwSweepWatch[ball] = RunService.Heartbeat:Connect(function()
		if not ball.Parent then
			stopThrowSweep(ball)
			return
		end
		if not isLiveThrow(ball) then
			ball:SetAttribute("InThrowWindow", false)
			stopThrowSweep(ball)
			return
		end

		local currentPos = ball.Position
		local delta = currentPos - lastPos
		local distance = delta.Magnitude
		if distance < 1e-4 then
			lastPos = currentPos
			return
		end

		local throwerId = ball:GetAttribute("LastThrowerUserId")
		local excludeList: { Instance } = { ball }
		if typeof(throwerId) == "number" then
			local thrower = Players:GetPlayerByUserId(throwerId)
			if thrower and thrower.Character then
				table.insert(excludeList, thrower.Character)
			end
		end

		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = excludeList

		local result = Workspace:Spherecast(lastPos, radius, delta, params)
		lastPos = currentPos

		if not result then
			return
		end

		local victim = playerFromPart(result.Instance)
		if not victim then
			return
		end

		debugElimination(`sweep hit detected on {victim.Name}`)
		if tryEliminateOnHit(ball, victim, true) then
			stopThrowSweep(ball)
		end
	end)
end

local function getOrCreateRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Config.REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local function getThrowRemote(): RemoteEvent
	local folder = getOrCreateRemotesFolder()
	local remote = folder:FindFirstChild(Config.THROW_REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = Config.THROW_REMOTE_NAME
	newRemote.Parent = folder
	return newRemote
end

local function getStartAimingRemote(): RemoteEvent
	local folder = getOrCreateRemotesFolder()
	local remote = folder:FindFirstChild(START_AIMING_REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = START_AIMING_REMOTE_NAME
	newRemote.Parent = folder
	return newRemote
end

local function publishClientTunables()
	local folder = getOrCreateRemotesFolder()
	folder:SetAttribute("AIM_POWER_CHARGE_SECONDS", Config.AIM_POWER_CHARGE_SECONDS)
	folder:SetAttribute("AIM_MAX_SECONDS", Config.AIM_MAX_SECONDS)
	folder:SetAttribute("BALL_MAX_HOLD_SECONDS", Config.BALL_MAX_HOLD_SECONDS)
	local practiceAttr = Config.LOBBY_PRACTICE_BALL_ATTR
	if typeof(practiceAttr) == "string" and practiceAttr ~= "" then
		folder:SetAttribute("LOBBY_PRACTICE_BALL_ATTR", practiceAttr)
	end
	local practiceTag = Config.LOBBY_PRACTICE_BALL_TAG
	if typeof(practiceTag) == "string" and practiceTag ~= "" then
		folder:SetAttribute("LOBBY_PRACTICE_BALL_TAG", practiceTag)
	end
	folder:SetAttribute("DEBUG_BALL_PHYSICS", DebugConfig.DEBUG_BALL_PHYSICS == true)
	folder:SetAttribute("DEBUG_BALL_VISUAL_EFFECTS", DebugConfig.DEBUG_BALL_VISUAL_EFFECTS == true)
	folder:SetAttribute("HIT_MIN_SPEED", Config.HIT_MIN_SPEED)
	folder:SetAttribute("DEFAULT_BALL_VISUAL_EFFECT", VisualEffectsConfig.DEFAULT_BALL_VISUAL_EFFECT)
	-- SpeedGlow + VFX (full mirror from DodgeballBallVisualEffectsConfig — re-paste this script when that module changes)
	folder:SetAttribute("SPEED_GLOW_HYSTERESIS_FRACTION", VisualEffectsConfig.SPEED_GLOW_HYSTERESIS_FRACTION)
	folder:SetAttribute("SPEED_GLOW_SHELL_DIAMETER_SCALE", VisualEffectsConfig.SPEED_GLOW_SHELL_DIAMETER_SCALE)
	folder:SetAttribute("SPEED_GLOW_FILL_TRANSPARENCY", VisualEffectsConfig.SPEED_GLOW_FILL_TRANSPARENCY)
	folder:SetAttribute("SPEED_GLOW_OUTLINE_TRANSPARENCY", VisualEffectsConfig.SPEED_GLOW_OUTLINE_TRANSPARENCY)
	folder:SetAttribute("SPEED_GLOW_MIN_OUTLINE_LUMINANCE", VisualEffectsConfig.SPEED_GLOW_MIN_OUTLINE_LUMINANCE)
	folder:SetAttribute("SPEED_GLOW_SPECTATOR_OUTLINE_COLOR", VisualEffectsConfig.SPEED_GLOW_SPECTATOR_OUTLINE_COLOR)
	folder:SetAttribute("DODGEBALL_TAG", Config.DODGEBALL_TAG)
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) == "string" and physicsTag ~= "" then
		folder:SetAttribute("BALL_PHYSICS_TAG", physicsTag)
	end
	local ballEffectAttr = VisualEffectsConfig.BALL_VISUAL_EFFECT_BALL_ATTR
	if typeof(ballEffectAttr) == "string" and ballEffectAttr ~= "" then
		folder:SetAttribute("BALL_VISUAL_EFFECT_BALL_ATTR", ballEffectAttr)
	end
	local playerEffectAttr = VisualEffectsConfig.BALL_VISUAL_EFFECT_PLAYER_ATTR
	if typeof(playerEffectAttr) == "string" and playerEffectAttr ~= "" then
		folder:SetAttribute("BALL_VISUAL_EFFECT_PLAYER_ATTR", playerEffectAttr)
	end
	local spectatorVfx = VisualEffectsConfig.BALL_VISUAL_EFFECT_SPECTATOR_COLOR
	if typeof(spectatorVfx) == "Color3" then
		folder:SetAttribute("BALL_VISUAL_EFFECT_SPECTATOR_COLOR", spectatorVfx)
	end
	-- Future: create RemoteFunction VisualEffectsConfig.SET_BALL_VISUAL_EFFECT_REMOTE_NAME to set
	-- player:GetAttribute(VisualEffectsConfig.BALL_VISUAL_EFFECT_PLAYER_ATTR) after validating allow-list.
end

local throwRemote = getThrowRemote()
local startAimingRemote = getStartAimingRemote()
publishClientTunables()

local function isPlayerOut(player: Player): boolean
	return player:GetAttribute("IsOut") == true
end

local function isMatchParticipant(player: Player): boolean
	return player:GetAttribute("MatchParticipant") == true
end

local function isLobbySpawn(spawn: SpawnLocation): boolean
	local name = Config.LOBBY_SPAWN_NAME
	if typeof(name) == "string" and name ~= "" and spawn.Name == name then
		return true
	end
	local tag = Config.LOBBY_SPAWN_TAG
	if typeof(tag) == "string" and tag ~= "" and CollectionService:HasTag(spawn, tag) then
		return true
	end
	return false
end

local function findTeamSpawnLocation(team: Team): SpawnLocation?
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") and not isLobbySpawn(descendant) then
			if descendant.Neutral == false and descendant.TeamColor == team.TeamColor then
				return descendant
			end
		end
	end
	return nil
end

local function findOpposingTeamSpawnLocation(team: Team): SpawnLocation?
	for _, teamName in Config.TEAM_NAMES do
		if typeof(teamName) == "string" and teamName ~= team.Name then
			local opposing = Teams:FindFirstChild(teamName)
			if opposing and opposing:IsA("Team") then
				return findTeamSpawnLocation(opposing)
			end
		end
	end
	return nil
end

local function rollDirectionForPlayer(player: Player): Vector3
	local character = player.Character
	local origin = if character then character:GetPivot().Position else Vector3.zero
	local fallback = Vector3.new(0, 0, -1)
	local team = player.Team
	if not team then
		return fallback
	end
	local opposingSpawn = findOpposingTeamSpawnLocation(team)
	if not opposingSpawn then
		return fallback
	end
	local target = opposingSpawn.CFrame.Position
	local flat = Vector3.new(target.X - origin.X, 0, target.Z - origin.Z)
	if flat.Magnitude < 0.5 then
		return fallback
	end
	return flat.Unit
end

local function clearHoldPenaltyForPlayer(player: Player)
	holdPenaltySlowToken[player] = (holdPenaltySlowToken[player] or 0) + 1
	player:SetAttribute(ATTR_HOLD_PENALTY_PICKUP_UNTIL, nil)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and player:GetAttribute("IsOut") ~= true then
			humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED
			humanoid.JumpPower = Config.DEFAULT_JUMP_POWER
		end
	end
end

local function applyHoldPenalty(player: Player)
	local now = workspace:GetServerTimeNow()
	player:SetAttribute(ATTR_HOLD_PENALTY_PICKUP_UNTIL, now + Config.HOLD_PENALTY_PICKUP_COOLDOWN_SECONDS)

	holdPenaltySlowToken[player] = (holdPenaltySlowToken[player] or 0) + 1
	local slowToken = holdPenaltySlowToken[player]

	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid and player:GetAttribute("IsOut") ~= true then
			local mult = Config.HOLD_PENALTY_WALK_SPEED_MULTIPLIER
			if typeof(mult) ~= "number" or mult <= 0 then
				mult = 0.5
			end
			humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED * mult
		end
	end

	task.delay(Config.HOLD_PENALTY_SLOW_SECONDS, function()
		if holdPenaltySlowToken[player] ~= slowToken then
			return
		end
		if player.Parent == nil then
			return
		end
		local penaltyUntil = player:GetAttribute(ATTR_HOLD_PENALTY_PICKUP_UNTIL)
		if typeof(penaltyUntil) == "number" and workspace:GetServerTimeNow() < penaltyUntil then
			-- Still in pickup cooldown; restore walk when slow ends anyway.
		end
		local char = player.Character
		if char and player:GetAttribute("IsOut") ~= true then
			local hum = char:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = Config.DEFAULT_WALK_SPEED
				hum.JumpPower = Config.DEFAULT_JUMP_POWER
			end
		end
	end)

	warn(`[DodgeballService] {player.Name} held the ball too long — rolled away + short penalty.`)
end

local rollBallFromMaxHold: (Player) -> ()

local function cancelHoldWatch(player: Player)
	holdWatchToken[player] = (holdWatchToken[player] or 0) + 1
	aimingBeforeThrow[player] = false
end

local function startHoldWatch(player: Player)
	cancelHoldWatch(player)
	aimingBeforeThrow[player] = false
	holdWatchToken[player] = (holdWatchToken[player] or 0) + 1
	local token = holdWatchToken[player]
	local maxHold = Config.BALL_MAX_HOLD_SECONDS
	task.delay(maxHold, function()
		if holdWatchToken[player] ~= token then
			return
		end
		if aimingBeforeThrow[player] then
			return
		end
		if not heldByPlayer[player] then
			return
		end
		rollBallFromMaxHold(player)
	end)
end

-- Player.CharacterAutoLoads is not in the public Player API (Studio may error); keep a pcall for forward compatibility.
local function setPlayerCharacterAutoLoads(_player: Player, _enabled: boolean)
	pcall(function()
		-- (_player :: any).CharacterAutoLoads = _enabled
	end)
end

local function getMatchPhase(): string
	local folder = ReplicatedStorage:FindFirstChild(Config.ROUND_STATUS_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		local phase = folder:GetAttribute("MatchPhase")
		if typeof(phase) == "string" then
			return phase
		end
	end
	return "Lobby"
end

local function sidelineOutPlayerViaBridge(player: Player)
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if not bridge then
		return
	end
	local bindable = bridge:FindFirstChild("SidelineOutCharacterAtLobby")
	if bindable and bindable:IsA("BindableFunction") then
		pcall(function()
			(bindable :: BindableFunction):Invoke(player)
		end)
	end
end

local function applyOutRespawnGate(_player: Player)
	-- Global Players.CharacterAutoLoads = false handles auto-respawn; IsOut gates explicit LoadCharacter.
end

local function destroyOutCharacterWhenReady(player: Player, character: Model)
	task.defer(function()
		if player:GetAttribute("IsOut") ~= true then
			return
		end
		if player.Character == character and character.Parent then
			character:Destroy()
		end
	end)
end

local function hookOutHumanoidDeath(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		return
	end
	humanoid.Died:Connect(function()
		if player:GetAttribute("IsOut") ~= true then
			return
		end
		setPlayerCharacterAutoLoads(player, false)
		destroyOutCharacterWhenReady(player, character)
	end)
end

local function handleStrayOutCharacterAfterDelay(player: Player)
	task.delay(0.2, function()
		if player:GetAttribute("IsOut") ~= true then
			return
		end
		local character = player.Character
		if not character or character.Parent == nil then
			return
		end
		if getMatchPhase() ~= "InMatch" or not isMatchParticipant(player) then
			character:Destroy()
			return
		end
		local fallback = Config.OUT_STRAY_RESPAWN_FALLBACK
		if typeof(fallback) == "string" and fallback == "lobby" then
			warn(`[DodgeballService] Stray OUT respawn for {player.Name} — sideline to lobby (fallback).`)
			sidelineOutPlayerViaBridge(player)
			return
		end
		character:Destroy()
	end)
end

local function suppressOutPlayerCharacter(player: Player, character: Model)
	if player:GetAttribute("IsOut") ~= true then
		return
	end
	setPlayerCharacterAutoLoads(player, false)
	hookOutHumanoidDeath(player, character)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		humanoid.Health = 0
	end
	destroyOutCharacterWhenReady(player, character)
	handleStrayOutCharacterAfterDelay(player)
end

local playerEliminatedEvent: BindableEvent? = nil

local function setPlayerOut(player: Player)
	if heldByPlayer[player] then
		dropBallFromPlayer(player)
	end
	clearHoldPenaltyForPlayer(player)
	player:SetAttribute("IsOut", true)
	setPlayerCharacterAutoLoads(player, false)
	local character = player.Character
	if character then
		suppressOutPlayerCharacter(player, character)
	end
	if playerEliminatedEvent then
		playerEliminatedEvent:Fire(player)
	end
end

local function clearPlayerOutIfNewLife(player: Player, character: Model)
	if player:GetAttribute("IsOut") == true then
		-- OUT mid-round: no Roblox auto-respawn (Players.CharacterAutoLoads = false); destroy stray bodies or sideline fallback.
		suppressOutPlayerCharacter(player, character)
		return
	end
	setPlayerCharacterAutoLoads(player, true)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED
		humanoid.JumpPower = Config.DEFAULT_JUMP_POWER
	end
end

dropBallFromPlayer = function(player: Player)
	cancelHoldWatch(player)
	local ball = heldByPlayer[player]
	if not ball then
		return
	end
	local weldConn = ballHeldConnection[ball]
	if weldConn then
		weldConn:Disconnect()
		ballHeldConnection[ball] = nil
	end
	for _, child in ball:GetChildren() do
		if child:IsA("WeldConstraint") and child.Name == "DodgeballHoldWeld" then
			child:Destroy()
		end
	end
	ball.Anchored = false
	ball.CanCollide = true
	ball.Parent = Workspace:FindFirstChild(Config.BALL_FOLDER_NAME) or Workspace
	heldByPlayer[player] = nil
end

local function attachBallToPlayer(player: Player, ball: BasePart)
	local character = player.Character
	if not character then
		return
	end
	local hand = character:FindFirstChild("RightHand") :: BasePart?
	if not hand then
		hand = character:FindFirstChild("Right Arm") :: BasePart?
	end
	if not hand then
		warn(`[DodgeballService] No RightHand on {player.Name}; cannot hold ball.`)
		return
	end

	dropBallFromPlayer(player)

	ball.Anchored = false
	ball.CanCollide = false
	ball.Massless = true
	ball.AssemblyLinearVelocity = Vector3.zero
	ball.AssemblyAngularVelocity = Vector3.zero
	ball.CFrame = hand.CFrame * CFrame.new(Config.CARRY_OFFSET)
	ball.Parent = character

	local weld = Instance.new("WeldConstraint")
	weld.Name = "DodgeballHoldWeld"
	weld.Part0 = hand
	weld.Part1 = ball
	weld.Parent = ball

	heldByPlayer[player] = ball
	ball:SetAttribute("HolderUserId", player.UserId)
	startHoldWatch(player)
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) ~= "string" or physicsTag == "" then
		physicsTag = "PhysicsBall"
	end
	BallPhysicsDebug.log(
		`pickup player={player.Name} ball={ball.Name} physicsTag={CollectionService:HasTag(ball, physicsTag)} owner={BallPhysicsDebug.formatNetworkOwner(
			ball
		)} massless={ball.Massless} weld=DodgeballHoldWeld`
	)
end

local function releaseBallForThrow(player: Player): BasePart?
	local ball = heldByPlayer[player]
	if not ball then
		return nil
	end
	for _, child in ball:GetChildren() do
		if child:IsA("WeldConstraint") and child.Name == "DodgeballHoldWeld" then
			child:Destroy()
		end
	end
	ball.Massless = false
	ball.CanCollide = true
	ball.Parent = Workspace:FindFirstChild(Config.BALL_FOLDER_NAME) or Workspace
	ball:SetAttribute("HolderUserId", nil)
	heldByPlayer[player] = nil
	local ownerBefore = BallPhysicsDebug.formatNetworkOwner(ball)
	-- Welded carry often assigns the ball to the client; server impulses only apply with server ownership.
	if ball:CanSetNetworkOwnership() then
		pcall(function()
			ball:SetNetworkOwner(nil)
		end)
	end
	local ownerAfter = BallPhysicsDebug.formatNetworkOwner(ball)
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) ~= "string" or physicsTag == "" then
		physicsTag = "PhysicsBall"
	end
	BallPhysicsDebug.log(
		`release player={player.Name} ball={ball.Name} physicsTag={CollectionService:HasTag(ball, physicsTag)} ownerBefore={ownerBefore} ownerAfter={ownerAfter} massless={ball.Massless}`
	)
	ThrowerCollision.beginThrowerGrace(player, ball)
	return ball
end

rollBallFromMaxHold = function(player: Player)
	if not isMatchParticipant(player) or isPlayerOut(player) then
		return
	end
	local ball = heldByPlayer[player]
	if not ball then
		return
	end
	cancelHoldWatch(player)

	local direction = rollDirectionForPlayer(player)
	local released = releaseBallForThrow(player)
	if not released then
		return
	end

	released:SetAttribute("LastThrowTime", 0)
	released:SetAttribute("LastThrowerUserId", nil)
	released:SetAttribute("LastThrowSpeed", 0)
	released:SetAttribute("InThrowWindow", false)

	local mass = released.AssemblyMass
	released:ApplyImpulse(direction * Config.HOLD_ROLL_IMPULSE * mass)

	applyHoldPenalty(player)
end

local function sanitizePowerMultiplier(input: any): number
	if typeof(input) ~= "number" then
		return 1
	end
	return math.clamp(input, 0, 1)
end

local function throwBall(player: Player, lookDirection: Vector3, powerMultiplier: number)
	if not isMatchParticipant(player) then
		return
	end
	if isPlayerOut(player) then
		return
	end
	local ball = heldByPlayer[player]
	if not ball then
		return
	end
	if lookDirection.Magnitude < 0.01 then
		return
	end
	cancelHoldWatch(player)
	local direction = lookDirection.Unit
	local power = sanitizePowerMultiplier(powerMultiplier)
	local released = releaseBallForThrow(player)
	if not released then
		return
	end
	ACTIVE_PROFILE:onThrowStarted({
		ball = released,
		thrower = player,
		direction = direction,
		powerMultiplier = power,
	})
	ACTIVE_PROFILE:throw({
		ball = released,
		thrower = player,
		direction = direction,
		powerMultiplier = power,
	})

	released.CanTouch = true
	released.CanCollide = true

	local impulseMag = Config.THROW_IMPULSE * released.AssemblyMass * power
	local spinRate = Config.THROW_SIDE_SPIN_RAD_PER_SEC
	if typeof(spinRate) ~= "number" then
		spinRate = 0
	end
	local spinMag = released.AssemblyAngularVelocity.Magnitude
	BallPhysicsDebug.log(
		`throw player={player.Name} power={string.format("%.2f", power)} impulseMag≈{string.format("%.1f", impulseMag)} spinConfig={spinRate} spinMag={string.format(
			"%.2f",
			spinMag
		)} LastThrowSpeed={released:GetAttribute("LastThrowSpeed")} owner={BallPhysicsDebug.formatNetworkOwner(
			released
		)}`
	)
	local ballPhysicsEntry = ReplicatedStorage:FindFirstChild("BallPhysics")
	if ballPhysicsEntry and ballPhysicsEntry:IsA("ModuleScript") then
		local ok, bp = pcall(require, ballPhysicsEntry)
		if ok and typeof(bp.isEffectEnabled) == "function" then
			BallPhysicsDebug.log(
				`effects magnus={bp.isEffectEnabled("MagnusForce")} knuckle={bp.isEffectEnabled("KnuckleBall")} antiGravity={bp.isEffectEnabled(
					"AntiGravity"
				)} angularDamping={bp.isEffectEnabled("AngularDamping")}`
			)
		end
	end
	local sampledBall = released
	task.delay(2, function()
		if sampledBall.Parent then
			BallPhysicsDebug.logBallState(sampledBall, "throw+2s")
		end
	end)

	local throwSpeed = released:GetAttribute("LastThrowSpeed")
	if typeof(throwSpeed) == "number" then
		debugElimination(`throw started (speed ≈ {throwSpeed} studs/s)`)
	end

	startThrowSweep(released)
end

local lastPickupTime: { [Player]: number } = {}

local function tryPickup(player: Player, ball: BasePart)
	if not isMatchParticipant(player) then
		return
	end
	if isPlayerOut(player) then
		return
	end
	if heldByPlayer[player] then
		return
	end
	local holderId = ball:GetAttribute("HolderUserId")
	if typeof(holderId) == "number" then
		return
	end
	local now = workspace:GetServerTimeNow()
	local penaltyUntil = player:GetAttribute(ATTR_HOLD_PENALTY_PICKUP_UNTIL)
	if typeof(penaltyUntil) == "number" and now < penaltyUntil then
		return
	end
	local last = lastPickupTime[player]
	if last and now - last < Config.PICKUP_COOLDOWN_SECONDS then
		return
	end
	local speed = ball.AssemblyLinearVelocity.Magnitude
	if speed >= Config.PICKUP_MAX_SPEED then
		return
	end
	lastPickupTime[player] = now
	attachBallToPlayer(player, ball)
end

tryEliminateOnHit = function(ball: BasePart, victim: Player, fromSweep: boolean): boolean
	local live = isLiveThrow(ball)
	local speed: number
	if fromSweep or live then
		local lastThrow = ball:GetAttribute("LastThrowSpeed")
		speed = if typeof(lastThrow) == "number" then lastThrow else ball.AssemblyLinearVelocity.Magnitude
	else
		speed = ball.AssemblyLinearVelocity.Magnitude
	end

	if speed < Config.HIT_MIN_SPEED then
		if fromSweep or live then
			debugElimination(`hit but speed {speed} < HIT_MIN_SPEED {Config.HIT_MIN_SPEED}`)
		else
			debugElimination("ball too slow (not a live throw)")
		end
		return false
	end

	local throwTime = ball:GetAttribute("LastThrowTime")
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwTime) ~= "number" or typeof(throwerId) ~= "number" then
		debugElimination("missing LastThrowTime or LastThrowerUserId")
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now - throwTime > Config.THROW_OUT_WINDOW_SECONDS then
		debugElimination("throw window expired")
		return false
	end
	if victim.UserId == throwerId then
		debugElimination("victim is thrower")
		return false
	end
	local thrower = Players:GetPlayerByUserId(throwerId)
	if not thrower or not thrower.Team or not victim.Team then
		debugElimination("thrower or victim has no team")
		return false
	end
	if thrower.Team == victim.Team then
		debugElimination("same team (friendly)")
		return false
	end
	if isPlayerOut(victim) then
		debugElimination("victim already out")
		return false
	end

	ball:SetAttribute("InThrowWindow", false)
	stopThrowSweep(ball)
	setPlayerOut(victim)
	dropBallFromPlayer(victim)
	debugElimination(`elimination success: {victim.Name} is OUT (hit by throw from user {throwerId})`)
	warn(`[DodgeballService] {victim.Name} is OUT (hit by throw from user {throwerId}).`)
	return true
end

local touchDebounce: { [BasePart]: boolean } = {}

local function onBallTouched(ball: BasePart, hit: BasePart)
	if touchDebounce[ball] then
		return
	end
	local victim = playerFromPart(hit)
	if not victim then
		return
	end
	touchDebounce[ball] = true
	task.delay(0.1, function()
		touchDebounce[ball] = nil
	end)

	local holderId = ball:GetAttribute("HolderUserId")
	if typeof(holderId) == "number" then
		return
	end

	-- Live throws are handled by Heartbeat spherecast sweeps, not Touched.
	if isLiveThrow(ball) then
		return
	end

	local speed = ball.AssemblyLinearVelocity.Magnitude
	if speed >= Config.HIT_MIN_SPEED then
		tryEliminateOnHit(ball, victim, false)
	else
		tryPickup(victim, ball)
	end
end

local function hookBall(ball: BasePart)
	if not ball:IsA("BasePart") then
		return
	end
	BallTemplate.applyAppearance(ball)
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) ~= "string" or physicsTag == "" then
		physicsTag = "PhysicsBall"
	end
	if BallPhysicsDebug.isEnabled() and not CollectionService:HasTag(ball, physicsTag) then
		BallPhysicsDebug.warn(`arena hookBall missing physics tag tag={physicsTag} ball={ball:GetFullName()}`)
	end
	ball:SetAttribute("LastThrowTime", ball:GetAttribute("LastThrowTime") or 0)
	ball:SetAttribute("LastThrowSpeed", ball:GetAttribute("LastThrowSpeed") or 0)
	if ball:GetAttribute("InThrowWindow") == nil then
		ball:SetAttribute("InThrowWindow", false)
	end
	ball.Touched:Connect(function(hit)
		onBallTouched(ball, hit)
	end)
end

local function gatherBalls(): { BasePart }
	local seen: { [BasePart]: boolean } = {}
	local list: { BasePart } = {}
	local function add(part: BasePart)
		if not seen[part] then
			seen[part] = true
			table.insert(list, part)
		end
	end
	local folder = Workspace:FindFirstChild(Config.BALL_FOLDER_NAME)
	if folder then
		for _, child in folder:GetDescendants() do
			if child:IsA("BasePart") then
				add(child)
			end
		end
	end
	for _, tagged in CollectionService:GetTagged(Config.DODGEBALL_TAG) do
		if tagged:IsA("BasePart") then
			add(tagged)
		end
	end
	return list
end

local function rememberBallSpawn(ball: BasePart)
	-- Saved once so RoundService can put balls back after each round.
	if ball:GetAttribute("SpawnCFrame") == nil then
		ball:SetAttribute("SpawnCFrame", ball.CFrame)
	end
end

local function dropEveryHeldBall()
	for player, _ in heldByPlayer do
		dropBallFromPlayer(player)
	end
end

local function clearEveryPlayerOut()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("IsOut", false)
		setPlayerCharacterAutoLoads(player, true)
		clearHoldPenaltyForPlayer(player)
	end
end

local function hookOutRespawnGate(player: Player)
	applyOutRespawnGate(player)
	player:GetAttributeChangedSignal("IsOut"):Connect(function()
		applyOutRespawnGate(player)
	end)
end

local function resetEveryBallToSpawn()
	for _, ball in gatherBalls() do
		stopThrowSweep(ball)
		local spawnCf = ball:GetAttribute("SpawnCFrame")
		if typeof(spawnCf) == "CFrame" then
			ball.CFrame = spawnCf
		end
		ball.AssemblyLinearVelocity = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero
		ball.Anchored = false
		ball.CanCollide = true
		ball:SetAttribute("HolderUserId", nil)
		ball:SetAttribute("LastThrowerUserId", nil)
		ball:SetAttribute("LastThrowTime", 0)
		ball:SetAttribute("InThrowWindow", false)
		ball:SetAttribute("LastThrowSpeed", 0)
	end
	dropEveryHeldBall()
end

local function ensureRoundBridge(): Folder
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if bridge and bridge:IsA("Folder") then
		return bridge
	end
	bridge = Instance.new("Folder")
	bridge.Name = "DodgeballRoundBridge"
	bridge.Parent = ServerScriptService
	return bridge
end

local function ensureBindableFunction(parent: Instance, name: string): BindableFunction
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("BindableFunction") then
		return existing
	end
	local fn = Instance.new("BindableFunction")
	fn.Name = name
	fn.Parent = parent
	return fn
end

local function wireRoundBridge()
	local bridge = ensureRoundBridge()

	playerEliminatedEvent = bridge:FindFirstChild("PlayerEliminated") :: BindableEvent?
	if not playerEliminatedEvent then
		local ev = Instance.new("BindableEvent")
		ev.Name = "PlayerEliminated"
		ev.Parent = bridge
		playerEliminatedEvent = ev
	end

	local dropFn = ensureBindableFunction(bridge, "DropAllHeldBalls")
	dropFn.OnInvoke = function()
		dropEveryHeldBall()
		return true
	end

	local clearFn = ensureBindableFunction(bridge, "ClearAllOuts")
	clearFn.OnInvoke = function()
		clearEveryPlayerOut()
		return true
	end

	local resetFn = ensureBindableFunction(bridge, "ResetBallsToSpawn")
	resetFn.OnInvoke = function()
		resetEveryBallToSpawn()
		return true
	end
end

local function initializeBalls()
	local balls = gatherBalls()
	if #balls == 0 then
		warn(
			`[DodgeballService] No dodgeballs found. Add Parts under Workspace/{Config.BALL_FOLDER_NAME} or tag them {Config.DODGEBALL_TAG}.`
		)
		return
	end
	for _, ball in balls do
		rememberBallSpawn(ball)
		hookBall(ball)
	end
end

local function watchBallFolder()
	local folder = Workspace:FindFirstChild(Config.BALL_FOLDER_NAME)
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = Config.BALL_FOLDER_NAME
		folder.Parent = Workspace
		warn(`[DodgeballService] Created empty Workspace/{Config.BALL_FOLDER_NAME} — add ball Parts to play.`)
	end
	folder.ChildAdded:Connect(function(child)
		if child:IsA("BasePart") then
			rememberBallSpawn(child)
			hookBall(child)
		end
	end)
	CollectionService:GetInstanceAddedSignal(Config.DODGEBALL_TAG):Connect(function(instance)
		if instance:IsA("BasePart") then
			rememberBallSpawn(instance)
			hookBall(instance)
		end
	end)
end

local function sanitizeDirection(input: any): Vector3?
	if typeof(input) ~= "Vector3" then
		return nil
	end
	if input.Magnitude > 1.5 then
		return input.Unit
	end
	if input.Magnitude < 0.05 then
		return nil
	end
	return input.Unit
end

startAimingRemote.OnServerEvent:Connect(function(player: Player)
	if not isMatchParticipant(player) or isPlayerOut(player) then
		return
	end
	if not heldByPlayer[player] then
		return
	end
	aimingBeforeThrow[player] = true
end)

throwRemote.OnServerEvent:Connect(function(player: Player, direction: any, powerMultiplier: any)
	local dir = sanitizeDirection(direction)
	if not dir then
		return
	end
	if not isMatchParticipant(player) then
		return
	end
	if isPlayerOut(player) then
		return
	end
	if not heldByPlayer[player] then
		return
	end
	throwBall(player, dir, powerMultiplier)
end)

Players.PlayerAdded:Connect(function(player)
	hookOutRespawnGate(player)
	player.CharacterAdded:Connect(function(character)
		clearPlayerOutIfNewLife(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	dropBallFromPlayer(player)
	heldByPlayer[player] = nil
	cancelHoldWatch(player)
	holdPenaltySlowToken[player] = nil
end)

for _, player in Players:GetPlayers() do
	hookOutRespawnGate(player)
	player.CharacterAdded:Connect(function(character)
		clearPlayerOutIfNewLife(player, character)
	end)
end

wireRoundBridge()
watchBallFolder()
initializeBalls()
