-- Studio setup: LobbyPracticeBallService.md
-- Paste as Script named LobbyPracticeBallService under ServerScriptService.
-- Lobby/spectator practice balls: spawn, pickup, throw via DefaultThrow + DodgeballRemotes (same as match balls).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))
local BallTemplate = require(ServerScriptService:WaitForChild("DodgeballBallTemplate"))
local ThrowerCollision = require(ServerScriptService:WaitForChild("DodgeballThrowerCollision"))
local BallPhysicsDebug = require(ServerScriptService:WaitForChild("DodgeballBallPhysicsDebug"))

local throwFolder = ServerScriptService:WaitForChild("throw")
local DefaultThrow = require(throwFolder:WaitForChild("DefaultThrow"))

local ATTR_LOBBY_AREA_ID = "LobbyBallAreaId"

local function lobbyPracticeAttrName(): string
	local name = Config.LOBBY_PRACTICE_BALL_ATTR
	if typeof(name) == "string" and name ~= "" then
		return name
	end
	return "IsLobbyPracticeBall"
end
local START_AIMING_REMOTE_NAME = "StartAiming"
local ATTR_HOLD_PENALTY_PICKUP_UNTIL = "HoldPenaltyPickupUntil"

local heldByPlayer: { [Player]: BasePart } = {}
local aimBeforeThrow: { [Player]: boolean } = {}
local holdWatchToken: { [Player]: number } = {}
local holdPenaltySlowToken: { [Player]: number } = {}
local lastPickupTime: { [Player]: number } = {}
local touchDebounce: { [BasePart]: boolean } = {}
local recoverSweepWatch: { [BasePart]: RBXScriptConnection } = {}

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

local function isMatchParticipant(player: Player): boolean
	return player:GetAttribute("MatchParticipant") == true
end

-- Same gates as LobbyService canSetJoinNextMatch (neutral lobby throw / spectator practice).
local function canUseLobbyPracticeBalls(player: Player): boolean
	if player:GetAttribute("IsOut") == true then
		return false
	end
	if isMatchParticipant(player) then
		return false
	end
	if player.Team ~= nil then
		return false
	end
	if not player.Neutral then
		return false
	end
	local phase = getMatchPhase()
	if phase ~= "Lobby" and phase ~= "InMatch" then
		return false
	end
	return true
end

local function getRemotesFolder(): Folder?
	local folder = ReplicatedStorage:FindFirstChild(Config.REMOTES_FOLDER_NAME)
	if folder and folder:IsA("Folder") then
		return folder
	end
	return nil
end

local function getThrowRemote(): RemoteEvent?
	local folder = getRemotesFolder()
	if not folder then
		return nil
	end
	local remote = folder:FindFirstChild(Config.THROW_REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local function getStartAimingRemote(): RemoteEvent?
	local folder = getRemotesFolder()
	if not folder then
		return nil
	end
	local remote = folder:FindFirstChild(START_AIMING_REMOTE_NAME)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	return nil
end

local function playerFromPart(part: BasePart): Player?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	if not model:FindFirstChildOfClass("Humanoid") then
		return nil
	end
	return Players:GetPlayerFromCharacter(model)
end

local function isLobbyPracticeBall(ball: BasePart): boolean
	if ball:GetAttribute(lobbyPracticeAttrName()) == true then
		return true
	end
	return CollectionService:HasTag(ball, Config.LOBBY_PRACTICE_BALL_TAG)
end

type SpawnVolume = {
	instance: Instance,
	areaId: string,
	minCount: number,
	maxCount: number,
}

local function readAreaLimitFromInstance(inst: Instance, attrName: string, fallback: number): number
	local value = inst:GetAttribute(attrName)
	if typeof(value) == "number" and value >= 0 then
		return math.floor(value)
	end
	return fallback
end

local function gatherSpawnVolumes(): { SpawnVolume }
	local list: { SpawnVolume } = {}
	local seen: { [string]: boolean } = {}
	for _, inst in CollectionService:GetTagged(Config.LOBBY_BALL_SPAWN_VOLUME_TAG) do
		local areaId = inst:GetFullName()
		if seen[areaId] then
			continue
		end
		seen[areaId] = true
		local minC = readAreaLimitFromInstance(inst, "LobbyBallMin", Config.LOBBY_BALL_MIN_PER_AREA)
		local maxC = readAreaLimitFromInstance(inst, "LobbyBallMax", Config.LOBBY_BALL_MAX_PER_AREA)
		if maxC < minC then
			maxC = minC
		end
		table.insert(list, {
			instance = inst,
			areaId = areaId,
			minCount = minC,
			maxCount = maxC,
		})
	end
	return list
end

local function volumeWorldParts(volume: SpawnVolume): { BasePart }
	local parts: { BasePart } = {}
	if volume.instance:IsA("BasePart") then
		table.insert(parts, volume.instance)
	elseif volume.instance:IsA("Model") then
		for _, desc in volume.instance:GetDescendants() do
			if desc:IsA("BasePart") then
				table.insert(parts, desc)
			end
		end
	end
	return parts
end

local function randomPointInVolume(volume: SpawnVolume): Vector3?
	local parts = volumeWorldParts(volume)
	if #parts == 0 then
		return nil
	end
	local part = parts[math.random(1, #parts)]
	local halfHeight = BallTemplate.halfHeight()
	local size = part.Size
	local offsetX = (math.random() - 0.5) * size.X * 0.9
	local offsetZ = (math.random() - 0.5) * size.Z * 0.9
	local topLocal = Vector3.new(offsetX, size.Y * 0.5, offsetZ)
	local surfaceWorld = part.CFrame:PointToWorldSpace(topLocal)
	return surfaceWorld + Vector3.new(0, halfHeight, 0)
end

local function pointInsidePart(part: BasePart, worldPoint: Vector3): boolean
	local localPoint = part.CFrame:PointToObjectSpace(worldPoint)
	local half = part.Size * 0.5
	return math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z
end

local function isInsideExcludeZone(worldPoint: Vector3): boolean
	for _, inst in CollectionService:GetTagged(Config.LOBBY_BALL_EXCLUDE_ZONE_TAG) do
		if inst:IsA("BasePart") then
			if pointInsidePart(inst, worldPoint) then
				return true
			end
		elseif inst:IsA("Model") then
			for _, desc in inst:GetDescendants() do
				if desc:IsA("BasePart") and pointInsidePart(desc, worldPoint) then
					return true
				end
			end
		end
	end
	return false
end

local function ensureBallFolder(): Folder
	local existing = Workspace:FindFirstChild(Config.LOBBY_BALL_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.LOBBY_BALL_FOLDER_NAME
	folder.Parent = Workspace
	return folder
end

local dropBallFromPlayer: (Player) -> ()

local function listBallsInArea(areaId: string): { BasePart }
	local folder = Workspace:FindFirstChild(Config.LOBBY_BALL_FOLDER_NAME)
	local list: { BasePart } = {}
	if not folder then
		return list
	end
	for _, child in folder:GetChildren() do
		if child:IsA("BasePart") and isLobbyPracticeBall(child) then
			if child:GetAttribute(ATTR_LOBBY_AREA_ID) == areaId then
				local holderId = child:GetAttribute("HolderUserId")
				if typeof(holderId) ~= "number" then
					table.insert(list, child)
				end
			end
		end
	end
	return list
end

local function createLobbyBallAt(areaId: string, position: Vector3): BasePart
	local folder = ensureBallFolder()
	local ball = BallTemplate.createPart()
	ball.Name = "LobbyPracticeBall"
	ball.Position = position
	ball:SetAttribute(lobbyPracticeAttrName(), true)
	ball:SetAttribute(ATTR_LOBBY_AREA_ID, areaId)
	ball:SetAttribute("LastThrowTime", 0)
	ball:SetAttribute("LastThrowSpeed", 0)
	ball:SetAttribute("InThrowWindow", false)
	ball:SetAttribute("LobbyIdleSince", workspace:GetServerTimeNow())
	CollectionService:AddTag(ball, Config.LOBBY_PRACTICE_BALL_TAG)
	ball.Parent = folder
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) ~= "string" or physicsTag == "" then
		physicsTag = "PhysicsBall"
	end
	if BallPhysicsDebug.isEnabled() then
		if CollectionService:HasTag(ball, physicsTag) then
			BallPhysicsDebug.log(`lobby spawn ball={ball.Name} physicsTag=true area={areaId}`)
		else
			BallPhysicsDebug.warn(`lobby spawn missing physics tag={physicsTag} ball={ball.Name}`)
		end
	end
	return ball
end

local function stopRecoverSweep(ball: BasePart)
	local conn = recoverSweepWatch[ball]
	if conn then
		conn:Disconnect()
		recoverSweepWatch[ball] = nil
	end
end

local function markBallIdle(ball: BasePart)
	ball:SetAttribute("LobbyIdleSince", workspace:GetServerTimeNow())
end

local recoverAndRespawnBall: (BasePart, string) -> ()
local hookLobbyBall: (BasePart) -> ()
local maintainBallCounts: () -> ()

local function detachBallFromAnyPlayer(ball: BasePart)
	for player, held in heldByPlayer do
		if held == ball then
			dropBallFromPlayer(player)
			break
		end
	end
end

recoverAndRespawnBall = function(ball: BasePart, _reason: string)
	if not ball.Parent then
		return
	end
	stopRecoverSweep(ball)
	detachBallFromAnyPlayer(ball)
	local areaId = ball:GetAttribute(ATTR_LOBBY_AREA_ID)
	if typeof(areaId) ~= "string" then
		areaId = ""
	end
	ball:Destroy()

	if areaId ~= "" then
		for _, volume in gatherSpawnVolumes() do
			if volume.areaId == areaId then
				local pos = randomPointInVolume(volume)
				if pos then
					local newBall = createLobbyBallAt(areaId, pos)
					hookLobbyBall(newBall)
				end
				break
			end
		end
	end
	task.defer(maintainBallCounts)
end

local function ballCastRadius(ball: BasePart): number
	return math.max(ball.Size.X, ball.Size.Y, ball.Size.Z) * 0.5
end

local function isLiveLobbyThrow(ball: BasePart): boolean
	local throwTime = ball:GetAttribute("LastThrowTime")
	if typeof(throwTime) ~= "number" or throwTime <= 0 then
		return false
	end
	local now = workspace:GetServerTimeNow()
	if now - throwTime > Config.THROW_OUT_WINDOW_SECONDS then
		return false
	end
	return ball:GetAttribute("InThrowWindow") == true
end

local function startRecoverSweep(ball: BasePart)
	stopRecoverSweep(ball)
	local lastPos = ball.Position
	local radius = ballCastRadius(ball)

	recoverSweepWatch[ball] = RunService.Heartbeat:Connect(function()
		if not ball.Parent or not isLobbyPracticeBall(ball) then
			stopRecoverSweep(ball)
			return
		end
		if not isLiveLobbyThrow(ball) then
			ball:SetAttribute("InThrowWindow", false)
			stopRecoverSweep(ball)
			return
		end

		local currentPos = ball.Position
		if isInsideExcludeZone(currentPos) then
			recoverAndRespawnBall(ball, "exclude zone")
			return
		end

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

		local hitPlayer = playerFromPart(result.Instance)
		if hitPlayer and isMatchParticipant(hitPlayer) then
			recoverAndRespawnBall(ball, "hit match participant")
		end
	end)
end

dropBallFromPlayer = function(player: Player)
	local ball = heldByPlayer[player]
	if not ball then
		return
	end
	heldByPlayer[player] = nil
	for _, child in ball:GetChildren() do
		if child:IsA("WeldConstraint") and child.Name == "DodgeballHoldWeld" then
			child:Destroy()
		end
	end
	ball.Anchored = false
	ball.CanCollide = true
	ball.Parent = ensureBallFolder()
	ball:SetAttribute("HolderUserId", nil)
	markBallIdle(ball)
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
	ball:SetAttribute("LobbyIdleSince", nil)
	local physicsTag = Config.BALL_PHYSICS_TAG
	if typeof(physicsTag) ~= "string" or physicsTag == "" then
		physicsTag = "PhysicsBall"
	end
	BallPhysicsDebug.log(
		`lobby pickup player={player.Name} ball={ball.Name} physicsTag={CollectionService:HasTag(ball, physicsTag)} owner={BallPhysicsDebug.formatNetworkOwner(
			ball
		)} massless={ball.Massless} weld=DodgeballHoldWeld`
	)
	-- Lobby practice: no match hold timer / roll-away penalty.
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
	ball.Parent = ensureBallFolder()
	ball:SetAttribute("HolderUserId", nil)
	heldByPlayer[player] = nil
	local ownerBefore = BallPhysicsDebug.formatNetworkOwner(ball)
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
		`lobby release player={player.Name} ball={ball.Name} physicsTag={CollectionService:HasTag(ball, physicsTag)} ownerBefore={ownerBefore} ownerAfter={ownerAfter} massless={ball.Massless}`
	)
	ThrowerCollision.beginThrowerGrace(player, ball)
	return ball
end

local function cancelHoldWatch(player: Player)
	holdWatchToken[player] = (holdWatchToken[player] or 0) + 1
	aimBeforeThrow[player] = false
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
		if holdPenaltySlowToken[player] ~= slowToken or player.Parent == nil then
			return
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
end

local rollBallFromMaxHold: (Player) -> ()

rollBallFromMaxHold = function(player: Player)
	if not canUseLobbyPracticeBalls(player) then
		return
	end
	local ball = heldByPlayer[player]
	if not ball then
		return
	end
	cancelHoldWatch(player)
	local released = releaseBallForThrow(player)
	if not released then
		return
	end
	released:SetAttribute("LastThrowTime", 0)
	released:SetAttribute("LastThrowerUserId", nil)
	released:SetAttribute("LastThrowSpeed", 0)
	released:SetAttribute("InThrowWindow", false)
	local mass = released.AssemblyMass
	released:ApplyImpulse(Vector3.new(0, 0, -1) * Config.HOLD_ROLL_IMPULSE * mass)
	markBallIdle(released)
	applyHoldPenalty(player)
end

local function startHoldWatch(player: Player)
	cancelHoldWatch(player)
	holdWatchToken[player] = (holdWatchToken[player] or 0) + 1
	local token = holdWatchToken[player]
	local maxHold = Config.BALL_MAX_HOLD_SECONDS
	task.delay(maxHold, function()
		if holdWatchToken[player] ~= token or aimBeforeThrow[player] or not heldByPlayer[player] then
			return
		end
		rollBallFromMaxHold(player)
	end)
end

local function sanitizePowerMultiplier(input: any): number
	if typeof(input) ~= "number" then
		return 1
	end
	return math.clamp(input, 0, 1)
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

local function throwLobbyBall(player: Player, lookDirection: Vector3, powerMultiplier: number)
	if not canUseLobbyPracticeBalls(player) then
		return
	end
	local ball = heldByPlayer[player]
	if not ball or not isLobbyPracticeBall(ball) then
		return
	end
	cancelHoldWatch(player)
	local released = releaseBallForThrow(player)
	if not released then
		return
	end

	DefaultThrow:onThrowStarted({
		ball = released,
		thrower = player,
		direction = lookDirection,
		powerMultiplier = powerMultiplier,
	})
	DefaultThrow:throw({
		ball = released,
		thrower = player,
		direction = lookDirection,
		powerMultiplier = powerMultiplier,
	})

	released:SetAttribute("LobbyIdleSince", nil)

	local power = powerMultiplier
	if typeof(power) ~= "number" then
		power = 1
	end
	power = math.clamp(power, 0.05, 1)
	local impulseMag = Config.THROW_IMPULSE * released.AssemblyMass * power
	BallPhysicsDebug.log(
		`lobby throw player={player.Name} power={string.format("%.2f", power)} impulseMag≈{string.format(
			"%.1f",
			impulseMag
		)} spinMag={string.format("%.2f", released.AssemblyAngularVelocity.Magnitude)} LastThrowSpeed={released:GetAttribute(
			"LastThrowSpeed"
		)} owner={BallPhysicsDebug.formatNetworkOwner(released)}`
	)
	local sampledBall = released
	task.delay(2, function()
		if sampledBall.Parent then
			BallPhysicsDebug.logBallState(sampledBall, "lobby throw+2s")
		end
	end)

	startRecoverSweep(released)
end

local function tryPickup(player: Player, ball: BasePart)
	if not canUseLobbyPracticeBalls(player) then
		return
	end
	if not isLobbyPracticeBall(ball) then
		return
	end
	if isMatchParticipant(player) then
		recoverAndRespawnBall(ball, "match participant touched ball")
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

local function onBallTouched(ball: BasePart, hit: BasePart)
	if touchDebounce[ball] then
		return
	end
	local touchedPlayer = playerFromPart(hit)
	if not touchedPlayer then
		return
	end

	if isMatchParticipant(touchedPlayer) then
		touchDebounce[ball] = true
		task.delay(0.1, function()
			touchDebounce[ball] = nil
		end)
		recoverAndRespawnBall(ball, "touched match participant")
		return
	end

	if isLiveLobbyThrow(ball) then
		-- Physical bounce only; no gameplay on other players.
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

	tryPickup(touchedPlayer, ball)
end

hookLobbyBall = function(ball: BasePart)
	if not isLobbyPracticeBall(ball) then
		return
	end
	ball.Touched:Connect(function(hit)
		onBallTouched(ball, hit)
	end)
end

local function spawnMissingForArea(volume: SpawnVolume)
	local existing = listBallsInArea(volume.areaId)
	local count = #existing
	while count < volume.minCount do
		local pos = randomPointInVolume(volume)
		if not pos then
			warn(`[LobbyPracticeBallService] Could not pick spawn point in {volume.instance:GetFullName()}`)
			break
		end
		local ball = createLobbyBallAt(volume.areaId, pos)
		hookLobbyBall(ball)
		count += 1
	end
end

local function destroyExcessBall(ball: BasePart)
	stopRecoverSweep(ball)
	detachBallFromAnyPlayer(ball)
	ball:Destroy()
end

local function trimExcessForAreaFixed(volume: SpawnVolume)
	local balls = listBallsInArea(volume.areaId)
	while #balls > volume.maxCount do
		local ball = balls[#balls]
		balls[#balls] = nil
		destroyExcessBall(ball)
	end
end

maintainBallCounts = function()
	local volumes = gatherSpawnVolumes()
	if #volumes == 0 then
		return
	end
	for _, volume in volumes do
		trimExcessForAreaFixed(volume)
		spawnMissingForArea(volume)
	end
end

local function maintainIdleAndBounds()
	local folder = Workspace:FindFirstChild(Config.LOBBY_BALL_FOLDER_NAME)
	if not folder then
		return
	end
	local now = workspace:GetServerTimeNow()
	local idleLimit = Config.LOBBY_BALL_IDLE_TIMEOUT_SECONDS
	if typeof(idleLimit) ~= "number" or idleLimit <= 0 then
		idleLimit = 45
	end

	for _, child in folder:GetChildren() do
		if not child:IsA("BasePart") or not isLobbyPracticeBall(child) then
			continue
		end
		if typeof(child:GetAttribute("HolderUserId")) == "number" then
			continue
		end

		local speed = child.AssemblyLinearVelocity.Magnitude
		if isLiveLobbyThrow(child) or speed >= Config.PICKUP_MAX_SPEED then
			child:SetAttribute("LobbyIdleSince", nil)
			if isInsideExcludeZone(child.Position) then
				recoverAndRespawnBall(child, "exclude zone")
			end
			continue
		end

		if isInsideExcludeZone(child.Position) then
			recoverAndRespawnBall(child, "exclude zone")
			continue
		end

		local idleSince = child:GetAttribute("LobbyIdleSince")
		if typeof(idleSince) ~= "number" then
			if speed < Config.PICKUP_MAX_SPEED then
				markBallIdle(child)
			else
				child:SetAttribute("LobbyIdleSince", nil)
			end
			continue
		end

		if speed >= Config.PICKUP_MAX_SPEED then
			child:SetAttribute("LobbyIdleSince", nil)
			continue
		end

		if now - idleSince >= idleLimit then
			recoverAndRespawnBall(child, "idle timeout")
		end
	end
	maintainBallCounts()
end

local remotesWired = false

local function wireRemotes()
	if remotesWired then
		return
	end
	local throwRemote = getThrowRemote()
	local startAimingRemote = getStartAimingRemote()

	if not throwRemote then
		task.spawn(function()
			ReplicatedStorage:WaitForChild(Config.REMOTES_FOLDER_NAME, 120)
			wireRemotes()
		end)
		return
	end
	remotesWired = true

	if throwRemote then
		throwRemote.OnServerEvent:Connect(function(player: Player, direction: any, powerMultiplier: any)
			local dir = sanitizeDirection(direction)
			if not dir or not heldByPlayer[player] then
				return
			end
			if not isLobbyPracticeBall(heldByPlayer[player]) then
				return
			end
			throwLobbyBall(player, dir, sanitizePowerMultiplier(powerMultiplier))
		end)
	end

	if startAimingRemote then
		startAimingRemote.OnServerEvent:Connect(function(player: Player)
			if not canUseLobbyPracticeBalls(player) or not heldByPlayer[player] then
				return
			end
			if not isLobbyPracticeBall(heldByPlayer[player]) then
				return
			end
			aimBeforeThrow[player] = true
		end)
	end
end

local function onParticipantOrEligibilityChanged(player: Player)
	if isMatchParticipant(player) or not canUseLobbyPracticeBalls(player) then
		dropBallFromPlayer(player)
		cancelHoldWatch(player)
	end
end

local function hookPlayer(player: Player)
	player:GetAttributeChangedSignal("MatchParticipant"):Connect(function()
		onParticipantOrEligibilityChanged(player)
	end)
	player:GetAttributeChangedSignal("IsOut"):Connect(function()
		onParticipantOrEligibilityChanged(player)
	end)
	player:GetPropertyChangedSignal("Team"):Connect(function()
		onParticipantOrEligibilityChanged(player)
	end)
	player:GetPropertyChangedSignal("Neutral"):Connect(function()
		onParticipantOrEligibilityChanged(player)
	end)
	player.CharacterAdded:Connect(function()
		dropBallFromPlayer(player)
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
Players.PlayerRemoving:Connect(function(player)
	dropBallFromPlayer(player)
	cancelHoldWatch(player)
end)

for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

wireRemotes()
maintainBallCounts()

CollectionService:GetInstanceAddedSignal(Config.LOBBY_BALL_SPAWN_VOLUME_TAG):Connect(function()
	task.defer(maintainBallCounts)
end)

task.spawn(function()
	local interval = Config.LOBBY_BALL_MAINTENANCE_INTERVAL_SECONDS
	if typeof(interval) ~= "number" or interval < 1 then
		interval = 8
	end
	while true do
		task.wait(interval)
		maintainBallCounts()
		maintainIdleAndBounds()
	end
end)

local volumes = gatherSpawnVolumes()
if #volumes == 0 then
	warn(
		`[LobbyPracticeBallService] No spawn volumes tagged {Config.LOBBY_BALL_SPAWN_VOLUME_TAG}. Tag lobby Parts/Models in Studio — see LobbyPracticeBallService.md in repo.`
	)
end
