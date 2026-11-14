-- LocalScript: DodgeballThrowInput under StarterPlayer → StarterPlayerScripts
-- Hold F or left-click / gamepad A to aim; release to throw with power charge.
-- Creates ScreenGui "DodgeballAimGui" (crosshair + hold bar + power bar).

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AIM_FALLBACK_STUDS = 200
local ACTION_THROW_AIM = "DodgeballThrowAim"

local remotes = ReplicatedStorage:WaitForChild("DodgeballRemotes", 15)
if not remotes then
	warn("[DodgeballThrowInput] DodgeballRemotes folder missing — is DodgeballService running?")
	return
end

local throwRemote = remotes:WaitForChild("RequestThrow", 10) :: RemoteEvent
local startAimingRemote = remotes:WaitForChild("StartAiming", 10) :: RemoteEvent

local function readTunable(name: string, fallback: number): number
	local value = remotes:GetAttribute(name)
	if typeof(value) == "number" and value > 0 then
		return value
	end
	return fallback
end

local aimPowerChargeSeconds = readTunable("AIM_POWER_CHARGE_SECONDS", 1.25)
local aimMaxSeconds = readTunable("AIM_MAX_SECONDS", 4)
local ballMaxHoldSeconds = readTunable("BALL_MAX_HOLD_SECONDS", 5)

remotes:GetAttributeChangedSignal("AIM_POWER_CHARGE_SECONDS"):Connect(function()
	aimPowerChargeSeconds = readTunable("AIM_POWER_CHARGE_SECONDS", 1.25)
end)
remotes:GetAttributeChangedSignal("AIM_MAX_SECONDS"):Connect(function()
	aimMaxSeconds = readTunable("AIM_MAX_SECONDS", 4)
end)
remotes:GetAttributeChangedSignal("BALL_MAX_HOLD_SECONDS"):Connect(function()
	ballMaxHoldSeconds = readTunable("BALL_MAX_HOLD_SECONDS", 5)
end)

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DodgeballAimGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.Parent = playerGui

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(20, 20)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.Parent = screenGui

local crosshairH = Instance.new("Frame")
crosshairH.Name = "LineH"
crosshairH.Size = UDim2.new(1, 0, 0, 2)
crosshairH.Position = UDim2.fromScale(0, 0.5)
crosshairH.AnchorPoint = Vector2.new(0, 0.5)
crosshairH.BackgroundColor3 = Color3.new(1, 1, 1)
crosshairH.BorderSizePixel = 0
crosshairH.Parent = crosshair

local crosshairV = Instance.new("Frame")
crosshairV.Name = "LineV"
crosshairV.Size = UDim2.new(0, 2, 1, 0)
crosshairV.Position = UDim2.fromScale(0.5, 0)
crosshairV.AnchorPoint = Vector2.new(0.5, 0)
crosshairV.BackgroundColor3 = Color3.new(1, 1, 1)
crosshairV.BorderSizePixel = 0
crosshairV.Parent = crosshair

local holdBarBack = Instance.new("Frame")
holdBarBack.Name = "HoldBarBackground"
holdBarBack.AnchorPoint = Vector2.new(0.5, 1)
holdBarBack.Position = UDim2.new(0.5, 0, 1, -80)
holdBarBack.Size = UDim2.fromOffset(200, 14)
holdBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
holdBarBack.BorderSizePixel = 0
holdBarBack.Visible = false
holdBarBack.Parent = screenGui

local holdBarFill = Instance.new("Frame")
holdBarFill.Name = "HoldBarFill"
holdBarFill.Size = UDim2.fromScale(0, 1)
holdBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
holdBarFill.BorderSizePixel = 0
holdBarFill.Parent = holdBarBack

local holdBarLabel = Instance.new("TextLabel")
holdBarLabel.Name = "HoldBarLabel"
holdBarLabel.Size = UDim2.new(1, 0, 0, 20)
holdBarLabel.Position = UDim2.new(0, 0, 0, -22)
holdBarLabel.BackgroundTransparency = 1
holdBarLabel.TextColor3 = Color3.new(1, 1, 1)
holdBarLabel.TextStrokeTransparency = 0.5
holdBarLabel.Font = Enum.Font.GothamBold
holdBarLabel.TextSize = 14
holdBarLabel.Text = "Hold ball — aim soon!"
holdBarLabel.Parent = holdBarBack

local powerBarBack = Instance.new("Frame")
powerBarBack.Name = "PowerBarBackground"
powerBarBack.AnchorPoint = Vector2.new(0.5, 1)
powerBarBack.Position = UDim2.new(0.5, 0, 1, -50)
powerBarBack.Size = UDim2.fromOffset(200, 18)
powerBarBack.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
powerBarBack.BorderSizePixel = 0
powerBarBack.Visible = false
powerBarBack.Parent = screenGui

local powerBarFill = Instance.new("Frame")
powerBarFill.Name = "PowerBarFill"
powerBarFill.Size = UDim2.fromScale(0, 1)
powerBarFill.BackgroundColor3 = Color3.fromRGB(80, 180, 255)
powerBarFill.BorderSizePixel = 0
powerBarFill.Parent = powerBarBack

local powerBarLabel = Instance.new("TextLabel")
powerBarLabel.Name = "PowerBarLabel"
powerBarLabel.Size = UDim2.new(1, 0, 0, 20)
powerBarLabel.Position = UDim2.new(0, 0, 0, -22)
powerBarLabel.BackgroundTransparency = 1
powerBarLabel.TextColor3 = Color3.new(1, 1, 1)
powerBarLabel.TextStrokeTransparency = 0.5
powerBarLabel.Font = Enum.Font.GothamBold
powerBarLabel.TextSize = 14
powerBarLabel.Text = "Power 0%"
powerBarLabel.Parent = powerBarBack

local aiming = false
local aimBeganAt = 0
local holdBallSince: number? = nil
local heartbeatConn: RBXScriptConnection? = nil
local lastAimWorldPoint: Vector3? = nil

local function isSpectatorOrOut(): boolean
	if player:GetAttribute("MatchParticipant") ~= true then
		return true
	end
	if player:GetAttribute("IsOut") == true then
		return true
	end
	return false
end

local function localPlayerHoldsBall(): boolean
	local character = player.Character
	if not character then
		return false
	end
	for _, child in character:GetChildren() do
		if child:IsA("BasePart") and typeof(child:GetAttribute("HolderUserId")) == "number" then
			if child:GetAttribute("HolderUserId") == player.UserId then
				return true
			end
		end
	end
	return false
end

local function getThrowOrigin(): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local hand = character:FindFirstChild("RightHand") :: BasePart?
	if not hand then
		hand = character:FindFirstChild("Right Arm") :: BasePart?
	end
	if hand then
		return hand
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function computeAimWorldPoint(): Vector3?
	local camera = workspace.CurrentCamera
	if not camera then
		return nil
	end
	local viewport = camera.ViewportSize
	local ray = camera:ViewportPointToRay(viewport.X * 0.5, viewport.Y * 0.5)

	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local exclude: { Instance } = {}
	if player.Character then
		table.insert(exclude, player.Character)
	end
	params.FilterDescendantsInstances = exclude

	local result = workspace:Raycast(ray.Origin, ray.Direction * 1000, params)
	if result then
		return result.Position
	end
	return ray.Origin + ray.Direction * AIM_FALLBACK_STUDS
end

local function throwDirectionFromAim(aimPoint: Vector3): Vector3?
	local originPart = getThrowOrigin()
	if not originPart then
		return nil
	end
	local delta = aimPoint - originPart.Position
	if delta.Magnitude < 0.05 then
		return nil
	end
	return delta.Unit
end

local function setPowerUi(ratio: number)
	local clamped = math.clamp(ratio, 0, 1)
	powerBarFill.Size = UDim2.fromScale(clamped, 1)
	powerBarLabel.Text = `Power {math.floor(clamped * 100 + 0.5)}%`
end

local function setHoldUi(ratio: number)
	local clamped = math.clamp(ratio, 0, 1)
	holdBarFill.Size = UDim2.fromScale(clamped, 1)
	holdBarLabel.Text = `Hold ball — aim in {math.max(0, math.ceil((1 - clamped) * ballMaxHoldSeconds))}s`
end

local function stopAimHeartbeat()
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
end

local function endAimUi()
	aiming = false
	crosshair.Visible = false
	powerBarBack.Visible = false
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	stopAimHeartbeat()
end

local function fireThrow(powerRatio: number)
	local aimPoint = lastAimWorldPoint
	if not aimPoint then
		aimPoint = computeAimWorldPoint()
	end
	if not aimPoint then
		endAimUi()
		return
	end
	local direction = throwDirectionFromAim(aimPoint)
	if not direction then
		endAimUi()
		return
	end
	local power = math.clamp(powerRatio, 0.05, 1)
	throwRemote:FireServer(direction, power)
	endAimUi()
	holdBallSince = nil
	holdBarBack.Visible = false
end

local function beginAim()
	if aiming or isSpectatorOrOut() or not localPlayerHoldsBall() then
		return
	end
	aiming = true
	aimBeganAt = os.clock()
	startAimingRemote:FireServer()
	holdBallSince = nil
	holdBarBack.Visible = false

	crosshair.Visible = true
	powerBarBack.Visible = true
	setPowerUi(0)
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	stopAimHeartbeat()
	heartbeatConn = RunService.RenderStepped:Connect(function()
		if not aiming then
			return
		end
		lastAimWorldPoint = computeAimWorldPoint()

		local elapsed = os.clock() - aimBeganAt
		local powerRatio = if aimPowerChargeSeconds > 0 then math.min(1, elapsed / aimPowerChargeSeconds) else 1
		setPowerUi(powerRatio)

		if elapsed >= aimMaxSeconds then
			fireThrow(powerRatio)
		end
	end)
end

local function endAimAndThrow()
	if not aiming then
		return
	end
	local elapsed = os.clock() - aimBeganAt
	local powerRatio = if aimPowerChargeSeconds > 0 then math.min(1, elapsed / aimPowerChargeSeconds) else 1
	fireThrow(powerRatio)
end

local throwActionBound = false

local function onThrowAction(_actionName: string, inputState: Enum.UserInputState, _inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		beginAim()
	elseif inputState == Enum.UserInputState.End then
		endAimAndThrow()
	end
	return Enum.ContextActionResult.Sink
end

local function bindThrowAction()
	if throwActionBound then
		return
	end
	throwActionBound = true
	ContextActionService:BindActionAtPriority(
		ACTION_THROW_AIM,
		onThrowAction,
		false,
		Enum.ContextActionPriority.Medium.Value,
		Enum.KeyCode.F,
		Enum.UserInputType.MouseButton1,
		Enum.KeyCode.ButtonR2
	)
end

bindThrowAction()

RunService.RenderStepped:Connect(function()
	if aiming or isSpectatorOrOut() then
		if not aiming and holdBarBack.Visible then
			holdBarBack.Visible = false
			holdBallSince = nil
		end
		return
	end

	local holds = localPlayerHoldsBall()
	if holds then
		if not holdBallSince then
			holdBallSince = os.clock()
		end
		local elapsed = os.clock() - holdBallSince
		local ratio = if ballMaxHoldSeconds > 0 then math.min(1, elapsed / ballMaxHoldSeconds) else 0
		holdBarBack.Visible = true
		setHoldUi(ratio)
	else
		holdBallSince = nil
		holdBarBack.Visible = false
	end
end)

player.CharacterAdded:Connect(function()
	endAimUi()
	holdBallSince = nil
	holdBarBack.Visible = false
end)

player:GetAttributeChangedSignal("IsOut"):Connect(function()
	if isSpectatorOrOut() then
		endAimUi()
		holdBallSince = nil
		holdBarBack.Visible = false
	end
end)

player:GetAttributeChangedSignal("MatchParticipant"):Connect(function()
	if isSpectatorOrOut() then
		endAimUi()
		holdBallSince = nil
		holdBarBack.Visible = false
	end
end)