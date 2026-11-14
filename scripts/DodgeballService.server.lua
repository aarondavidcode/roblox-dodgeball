-- Paste as Script named DodgeballService under ServerScriptService.
-- Needs DodgeballConfig (ModuleScript), throw/DefaultThrow (ModuleScript), and Workspace/Dodgeballs.

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
local throwSpeedWatch: { [BasePart]: RBXScriptConnection } = {}

local function debugElimination(reason: string)
	if Config.DEBUG_ELIMINATION then
		warn(`[DodgeballService] Elimination blocked: {reason}`)
	end
end

-- Thrown ball: Touched often fires after physics settles, so AssemblyLinearVelocity can read ~0.
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

local function effectiveHitSpeed(ball: BasePart): number
	local inst = ball.AssemblyLinearVelocity.Magnitude
	if not isLiveThrow(ball) then
		return inst
	end
	local stored = 0
	local lastThrow = ball:GetAttribute("LastThrowSpeed")
	local peak = ball:GetAttribute("PeakThrowSpeed")
	if typeof(lastThrow) == "number" then
		stored = lastThrow
	end
	if typeof(peak) == "number" then
		stored = math.max(stored, peak)
	end
	return math.max(inst, stored)
end

local function stopThrowSpeedWatch(ball: BasePart)
	local conn = throwSpeedWatch[ball]
	if conn then
		conn:Disconnect()
		throwSpeedWatch[ball] = nil
	end
end

local function startThrowSpeedWatch(ball: BasePart)
	stopThrowSpeedWatch(ball)
	local peak = ball.AssemblyLinearVelocity.Magnitude
	local lastThrow = ball:GetAttribute("LastThrowSpeed")
	if typeof(lastThrow) == "number" then
		peak = math.max(peak, lastThrow)
	end
	ball:SetAttribute("PeakThrowSpeed", peak)
	ball:SetAttribute("InThrowWindow", true)

	throwSpeedWatch[ball] = RunService.Heartbeat:Connect(function()
		local currentPeak = ball:GetAttribute("PeakThrowSpeed")
		if typeof(currentPeak) ~= "number" then
			currentPeak = 0
		end
		local speed = ball.AssemblyLinearVelocity.Magnitude
		if speed > currentPeak then
			ball:SetAttribute("PeakThrowSpeed", speed)
		end
		if not isLiveThrow(ball) then
			ball:SetAttribute("InThrowWindow", false)
			stopThrowSpeedWatch(ball)
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

local function isPlayerOut(player: Player): boolean
	return player:GetAttribute("IsOut") == true
end

local function setPlayerOut(player: Player)
	player:SetAttribute("IsOut", true)
	local character = player.Character
	if character then
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.WalkSpeed = 0
			humanoid.JumpPower = 0
		end
	end
end

local function clearPlayerOutIfNewLife(player: Player, character: Model)
	player:SetAttribute("IsOut", false)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 16
		humanoid.JumpPower = 50
	end
end

local function dropBallFromPlayer(player: Player)
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
	startThrowSpeedWatch(released)
end

local lastPickupTime: { [Player]: number } = {}

local function tryPickup(player: Player, ball: BasePart)
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

local function tryEliminateOnHit(ball: BasePart, victim: Player)
	local live = isLiveThrow(ball)
	local speed = effectiveHitSpeed(ball)
	if not live then
		if speed < Config.HIT_MIN_SPEED then
			debugElimination("ball too slow (not a live throw)")
			return
		end
	else
		-- During the throw window, trust LastThrowSpeed / PeakThrowSpeed; Touched velocity is unreliable.
		if speed < Config.HIT_MIN_SPEED then
			debugElimination(`live throw but effective speed {speed} < HIT_MIN_SPEED {Config.HIT_MIN_SPEED}`)
			return
		end
	end
	local throwTime = ball:GetAttribute("LastThrowTime")
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwTime) ~= "number" or typeof(throwerId) ~= "number" then
		debugElimination("missing LastThrowTime or LastThrowerUserId")
		return
	end
	local now = workspace:GetServerTimeNow()
	if now - throwTime > Config.THROW_OUT_WINDOW_SECONDS then
		debugElimination("throw window expired")
		return
	end
	if victim.UserId == throwerId then
		debugElimination("victim is thrower")
		return
	end
	local thrower = Players:GetPlayerByUserId(throwerId)
	if not thrower or not thrower.Team or not victim.Team then
		debugElimination("thrower or victim has no team")
		return
	end
	if thrower.Team == victim.Team then
		debugElimination("same team (friendly)")
		return
	end
	if isPlayerOut(victim) then
		debugElimination("victim already out")
		return
	end
	ball:SetAttribute("InThrowWindow", false)
	stopThrowSpeedWatch(ball)
	setPlayerOut(victim)
	dropBallFromPlayer(victim)
	warn(`[DodgeballService] {victim.Name} is OUT (hit by throw from user {throwerId}).`)
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

	if isLiveThrow(ball) then
		local throwerId = ball:GetAttribute("LastThrowerUserId")
		if typeof(throwerId) == "number" and victim.UserId == throwerId then
			return
		end
		tryEliminateOnHit(ball, victim)
		return
	end

	-- Rolling / settled ball: instantaneous speed decides pickup vs elimination.
	local speed = ball.AssemblyLinearVelocity.Magnitude
	if speed >= Config.HIT_MIN_SPEED then
		tryEliminateOnHit(ball, victim)
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
	ball:SetAttribute("PeakThrowSpeed", ball:GetAttribute("PeakThrowSpeed") or 0)
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

local function initializeBalls()
	local balls = gatherBalls()
	if #balls == 0 then
		warn(
			`[DodgeballService] No dodgeballs found. Add Parts under Workspace/{Config.BALL_FOLDER_NAME} or tag them {Config.DODGEBALL_TAG}.`
		)
		return
	end
	for _, ball in balls do
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
			hookBall(child)
		end
	end)
	CollectionService:GetInstanceAddedSignal(Config.DODGEBALL_TAG):Connect(function(instance)
		if instance:IsA("BasePart") then
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

watchBallFolder()
initializeBalls()