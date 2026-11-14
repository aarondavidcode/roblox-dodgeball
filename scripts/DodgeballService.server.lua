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
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

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

local function debugElimination(message: string)
	if Config.DEBUG_ELIMINATION then
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

local throwRemote = getThrowRemote()

local function isPlayerOut(player: Player): boolean
	return player:GetAttribute("IsOut") == true
end

local function isMatchParticipant(player: Player): boolean
	return player:GetAttribute("MatchParticipant") == true
end

local playerEliminatedEvent: BindableEvent? = nil

local function setPlayerOut(player: Player)
	if heldByPlayer[player] then
		dropBallFromPlayer(player)
	end
	player:SetAttribute("IsOut", true)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Health = 0
		end
	end
	if playerEliminatedEvent then
		playerEliminatedEvent:Fire(player)
	end
end

local function clearPlayerOutIfNewLife(player: Player, character: Model)
	if player:GetAttribute("IsOut") == true then
		-- Still OUT this round — no instant respawn play; wait for RoundService LoadCharacter.
		task.defer(function()
			if player:GetAttribute("IsOut") ~= true then
				return
			end
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
		end)
		return
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED
		humanoid.JumpPower = Config.DEFAULT_JUMP_POWER
	end
end

dropBallFromPlayer = function(player: Player)
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
	return ball
end

local function throwBall(player: Player, lookDirection: Vector3)
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
	local direction = lookDirection.Unit
	local released = releaseBallForThrow(player)
	if not released then
		return
	end
	ACTIVE_PROFILE:onThrowStarted({
		ball = released,
		thrower = player,
		direction = direction,
	})
	ACTIVE_PROFILE:throw({
		ball = released,
		thrower = player,
		direction = direction,
	})

	released.CanTouch = true
	released.CanCollide = true
	pcall(function()
		released:SetNetworkOwner(nil)
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
		local character = player.Character
		if character then
			local humanoid = character:FindFirstChildOfClass("Humanoid")
			if humanoid then
				humanoid.WalkSpeed = Config.DEFAULT_WALK_SPEED
				humanoid.JumpPower = Config.DEFAULT_JUMP_POWER
			end
		end
	end
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
		warn(`[DodgeballService] Created empty Workspace/{Config.BALL_FOLDER_NAME} — add ball Parts for kids to play.`)
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

throwRemote.OnServerEvent:Connect(function(player: Player, direction: any)
	local dir = sanitizeDirection(direction)
	if not dir then
		return
	end
	if not isMatchParticipant(player) then
		return
	end
	if not heldByPlayer[player] then
		return
	end
	throwBall(player, dir)
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		clearPlayerOutIfNewLife(player, character)
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	dropBallFromPlayer(player)
	heldByPlayer[player] = nil
end)

for _, player in Players:GetPlayers() do
	player.CharacterAdded:Connect(function(character)
		clearPlayerOutIfNewLife(player, character)
	end)
end

wireRoundBridge()
watchBallFolder()
initializeBalls()