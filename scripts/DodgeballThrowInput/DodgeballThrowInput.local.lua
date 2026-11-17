-- Studio setup: DodgeballThrowInput.md
-- LocalScript: DodgeballThrowInput under StarterPlayer → StarterPlayerScripts
-- Hold F or left-click / gamepad A to aim; release to throw with power charge.
-- Creates ScreenGui "DodgeballAimGui" (crosshair + hold bar + power bar).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")

local UserGameSettings = UserSettings():GetService("UserGameSettings")

local SCRIPT_TAG = "[DodgeballThrowInput]"

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local AIM_FALLBACK_STUDS = 200
local ACTION_THROW_AIM = "DodgeballThrowAim"
local FREE_CURSOR_CAMERA_BIND = "DodgeballThrowFreeCursorCamera"
local ROUND_STATUS_FOLDER = "RoundStatus"

-- Tunables (defaults until DodgeballRemotes folder replicates)
local aimPowerChargeSeconds = 1.25
local aimMaxSeconds = 4
local ballMaxHoldSeconds = 5
local lobbyPracticeBallAttr = "IsLobbyPracticeBall"
local lobbyPracticeBallTag = "LobbyPracticeBall"

local remotes: Folder? = nil
local throwRemote: RemoteEvent? = nil
local startAimingRemote: RemoteEvent? = nil
local warnedMissingStartAiming = false
local warnedMissingThrow = false
local warnedMissingRemotesFolder = false

local function readTunable(name: string, fallback: number): number
	if remotes then
		local value = remotes:GetAttribute(name)
		if typeof(value) == "number" and value > 0 then
			return value
		end
	end
	return fallback
end

local function hookTunableSignals()
	if not remotes then
		return
	end
	remotes:GetAttributeChangedSignal("AIM_POWER_CHARGE_SECONDS"):Connect(function()
		aimPowerChargeSeconds = readTunable("AIM_POWER_CHARGE_SECONDS", 1.25)
	end)
	remotes:GetAttributeChangedSignal("AIM_MAX_SECONDS"):Connect(function()
		aimMaxSeconds = readTunable("AIM_MAX_SECONDS", 4)
	end)
	remotes:GetAttributeChangedSignal("BALL_MAX_HOLD_SECONDS"):Connect(function()
		ballMaxHoldSeconds = readTunable("BALL_MAX_HOLD_SECONDS", 5)
	end)
	remotes:GetAttributeChangedSignal("LOBBY_PRACTICE_BALL_ATTR"):Connect(function()
		local value = remotes and remotes:GetAttribute("LOBBY_PRACTICE_BALL_ATTR")
		if typeof(value) == "string" and value ~= "" then
			lobbyPracticeBallAttr = value
		end
	end)
	remotes:GetAttributeChangedSignal("LOBBY_PRACTICE_BALL_TAG"):Connect(function()
		local value = remotes and remotes:GetAttribute("LOBBY_PRACTICE_BALL_TAG")
		if typeof(value) == "string" and value ~= "" then
			lobbyPracticeBallTag = value
		end
	end)
	aimPowerChargeSeconds = readTunable("AIM_POWER_CHARGE_SECONDS", 1.25)
	aimMaxSeconds = readTunable("AIM_MAX_SECONDS", 4)
	ballMaxHoldSeconds = readTunable("BALL_MAX_HOLD_SECONDS", 5)
	local practiceAttr = remotes:GetAttribute("LOBBY_PRACTICE_BALL_ATTR")
	if typeof(practiceAttr) == "string" and practiceAttr ~= "" then
		lobbyPracticeBallAttr = practiceAttr
	end
	local practiceTag = remotes:GetAttribute("LOBBY_PRACTICE_BALL_TAG")
	if typeof(practiceTag) == "string" and practiceTag ~= "" then
		lobbyPracticeBallTag = practiceTag
	end
end

local function attachRemotes(folder: Folder)
	remotes = folder
	local throw = folder:WaitForChild("RequestThrow", 30)
	if throw and throw:IsA("RemoteEvent") then
		throwRemote = throw
	else
		if not warnedMissingThrow then
			warnedMissingThrow = true
			warn(`{SCRIPT_TAG} RequestThrow RemoteEvent missing — re-paste DodgeballService from the repo.`)
		end
	end
	local startAiming = folder:WaitForChild("StartAiming", 30)
	if startAiming and startAiming:IsA("RemoteEvent") then
		startAimingRemote = startAiming
	else
		if not warnedMissingStartAiming then
			warnedMissingStartAiming = true
			warn(
				`{SCRIPT_TAG} StartAiming RemoteEvent missing — re-paste DodgeballService from the repo (needed for hold rules).`
			)
		end
	end
	hookTunableSignals()
end

task.spawn(function()
	local folder = ReplicatedStorage:WaitForChild("DodgeballRemotes", 60)
	if folder and folder:IsA("Folder") then
		attachRemotes(folder)
		return
	end
	if not warnedMissingRemotesFolder then
		warnedMissingRemotesFolder = true
		warn(
			`{SCRIPT_TAG} DodgeballRemotes folder missing after 60s — is DodgeballService running under ServerScriptService?`
		)
	end
	ReplicatedStorage.ChildAdded:Connect(function(child)
		if child.Name == "DodgeballRemotes" and child:IsA("Folder") then
			attachRemotes(child)
		end
	end)
end)

-- ScreenGui is created immediately so Explorer shows DodgeballAimGui even if remotes are slow.
local staleGui = playerGui:FindFirstChild("DodgeballAimGui")
if staleGui then
	staleGui:Destroy()
end

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DodgeballAimGui"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 50
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Enabled = true
screenGui.Parent = playerGui

local function strokeFrame(frame: Frame, thickness: number, color: Color3)
	local stroke = Instance.new("UIStroke")
	stroke.Thickness = thickness
	stroke.Color = color
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = frame
	return stroke
end

local crosshair = Instance.new("Frame")
crosshair.Name = "Crosshair"
crosshair.AnchorPoint = Vector2.new(0.5, 0.5)
crosshair.Position = UDim2.fromScale(0.5, 0.5)
crosshair.Size = UDim2.fromOffset(32, 32)
crosshair.BackgroundTransparency = 1
crosshair.Visible = false
crosshair.ZIndex = 10
crosshair.Parent = screenGui

local crosshairH = Instance.new("Frame")
crosshairH.Name = "LineH"
crosshairH.Size = UDim2.new(1, 0, 0, 3)
crosshairH.Position = UDim2.fromScale(0, 0.5)
crosshairH.AnchorPoint = Vector2.new(0, 0.5)
crosshairH.BackgroundColor3 = Color3.fromRGB(255, 240, 64)
crosshairH.BorderSizePixel = 0
crosshairH.ZIndex = 11
crosshairH.Parent = crosshair
strokeFrame(crosshairH, 1.5, Color3.fromRGB(20, 20, 20))

local crosshairV = Instance.new("Frame")
crosshairV.Name = "LineV"
crosshairV.Size = UDim2.new(0, 3, 1, 0)
crosshairV.Position = UDim2.fromScale(0.5, 0)
crosshairV.AnchorPoint = Vector2.new(0.5, 0)
crosshairV.BackgroundColor3 = Color3.fromRGB(255, 240, 64)
crosshairV.BorderSizePixel = 0
crosshairV.ZIndex = 11
crosshairV.Parent = crosshair
strokeFrame(crosshairV, 1.5, Color3.fromRGB(20, 20, 20))

local holdBarBack = Instance.new("Frame")
holdBarBack.Name = "HoldBarBackground"
holdBarBack.AnchorPoint = Vector2.new(0.5, 1)
holdBarBack.Position = UDim2.new(0.5, 0, 1, -80)
holdBarBack.Size = UDim2.fromOffset(220, 16)
holdBarBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
holdBarBack.BorderSizePixel = 0
holdBarBack.Visible = false
holdBarBack.ZIndex = 5
holdBarBack.Parent = screenGui
strokeFrame(holdBarBack, 1, Color3.fromRGB(80, 80, 80))

local holdBarFill = Instance.new("Frame")
holdBarFill.Name = "HoldBarFill"
holdBarFill.Size = UDim2.fromScale(0, 1)
holdBarFill.BackgroundColor3 = Color3.fromRGB(255, 200, 80)
holdBarFill.BorderSizePixel = 0
holdBarFill.ZIndex = 6
holdBarFill.Parent = holdBarBack

local holdBarLabel = Instance.new("TextLabel")
holdBarLabel.Name = "HoldBarLabel"
holdBarLabel.Size = UDim2.new(1, 0, 0, 22)
holdBarLabel.Position = UDim2.new(0, 0, 0, -24)
holdBarLabel.BackgroundTransparency = 1
holdBarLabel.TextColor3 = Color3.new(1, 1, 1)
holdBarLabel.TextStrokeTransparency = 0.3
holdBarLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
holdBarLabel.Font = Enum.Font.GothamBold
holdBarLabel.TextSize = 15
holdBarLabel.Text = "Hold ball — aim soon!"
holdBarLabel.ZIndex = 7
holdBarLabel.Parent = holdBarBack

local powerBarBack = Instance.new("Frame")
powerBarBack.Name = "PowerBarBackground"
powerBarBack.AnchorPoint = Vector2.new(0.5, 1)
powerBarBack.Position = UDim2.new(0.5, 0, 1, -52)
powerBarBack.Size = UDim2.fromOffset(220, 20)
powerBarBack.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
powerBarBack.BorderSizePixel = 0
powerBarBack.Visible = false
powerBarBack.ZIndex = 5
powerBarBack.Parent = screenGui
strokeFrame(powerBarBack, 1, Color3.fromRGB(80, 80, 80))

local powerBarFill = Instance.new("Frame")
powerBarFill.Name = "PowerBarFill"
powerBarFill.Size = UDim2.fromScale(0, 1)
powerBarFill.BackgroundColor3 = Color3.fromRGB(80, 200, 255)
powerBarFill.BorderSizePixel = 0
powerBarFill.ZIndex = 6
powerBarFill.Parent = powerBarBack

local powerBarLabel = Instance.new("TextLabel")
powerBarLabel.Name = "PowerBarLabel"
powerBarLabel.Size = UDim2.new(1, 0, 0, 22)
powerBarLabel.Position = UDim2.new(0, 0, 0, -24)
powerBarLabel.BackgroundTransparency = 1
powerBarLabel.TextColor3 = Color3.new(1, 1, 1)
powerBarLabel.TextStrokeTransparency = 0.3
powerBarLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
powerBarLabel.Font = Enum.Font.GothamBold
powerBarLabel.TextSize = 15
powerBarLabel.Text = "Power 0%"
powerBarLabel.ZIndex = 7
powerBarLabel.Parent = powerBarBack

local aiming = false
local aimUsesFreeCursor = false
local aimBeganAt = 0
local holdBallSince: number? = nil
local heartbeatConn: RBXScriptConnection? = nil
local lastAimWorldPoint: Vector3? = nil
local savedRotationType: Enum.RotationType? = nil
local rightMouseHeld = false

-- Mouse + keyboard: free cursor and screen-point aim. Touch and gamepad: center lock (unchanged).
local function shouldUseFreeCursorAim(inputObject: InputObject): boolean
	local inputType = inputObject.UserInputType
	if inputType == Enum.UserInputType.Gamepad1 or inputType == Enum.UserInputType.Gamepad2 then
		return false
	end
	if inputType == Enum.UserInputType.Touch then
		return false
	end
	if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
		return false
	end
	return UserInputService.MouseEnabled
end

-- PlayerModule / shift lock can steer rotation and mouse lock toward the cursor; re-apply each aim frame.
local function applyFreeCursorCameraIndependence()
	UserGameSettings.RotationType = Enum.RotationType.MovementRelative
	UserInputService.MouseIconEnabled = true
	if not rightMouseHeld then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end

local function saveRotationTypeForAim()
	if savedRotationType == nil then
		savedRotationType = UserGameSettings.RotationType
	end
end

local function restoreRotationTypeAfterAim()
	if savedRotationType ~= nil then
		UserGameSettings.RotationType = savedRotationType
		savedRotationType = nil
	end
end

UserInputService.InputBegan:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseHeld = true
	end
end)

UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
	if input.UserInputType == Enum.UserInputType.MouseButton2 then
		rightMouseHeld = false
	end
end)

local function getMatchPhase(): string?
	local folder = ReplicatedStorage:FindFirstChild(ROUND_STATUS_FOLDER)
	if folder and folder:IsA("Folder") then
		local phase = folder:GetAttribute("MatchPhase")
		if typeof(phase) == "string" then
			return phase
		end
	end
	return nil
end

local function localPlayerHoldsBall(): boolean
	local character = player.Character
	if not character then
		return false
	end
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			local holderId = desc:GetAttribute("HolderUserId")
			if typeof(holderId) == "number" and holderId == player.UserId then
				return true
			end
			if desc:FindFirstChild("DodgeballHoldWeld") then
				return true
			end
		end
	end
	return false
end

local function canUseLobbyPractice(): boolean
	if player:GetAttribute("IsOut") == true then
		return false
	end
	if player:GetAttribute("MatchParticipant") == true then
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

local function heldBallPartLooksLikePractice(part: BasePart): boolean
	if part:GetAttribute(lobbyPracticeBallAttr) == true then
		return true
	end
	if part:GetAttribute("IsLobbyPracticeBall") == true then
		return true
	end
	if lobbyPracticeBallTag ~= "" and CollectionService:HasTag(part, lobbyPracticeBallTag) then
		return true
	end
	return false
end

local function localPlayerHoldsLobbyPracticeBall(): boolean
	local character = player.Character
	if not character then
		return false
	end
	for _, desc in character:GetDescendants() do
		if not desc:IsA("BasePart") then
			continue
		end
		if not heldBallPartLooksLikePractice(desc) then
			continue
		end
		local holderId = desc:GetAttribute("HolderUserId")
		if typeof(holderId) == "number" and holderId == player.UserId then
			return true
		end
		if desc:FindFirstChild("DodgeballHoldWeld") then
			return true
		end
	end
	return false
end

local function canThrowHeldBall(): boolean
	if player:GetAttribute("IsOut") == true then
		return false
	end
	if not localPlayerHoldsBall() then
		return false
	end
	local phase = getMatchPhase()
	-- Lobby: only practice balls exist for neutrals; do not require attr/tag race on client.
	if phase == "Lobby" then
		return canUseLobbyPractice()
	end
	if localPlayerHoldsLobbyPracticeBall() then
		return canUseLobbyPractice()
	end
	if phase == "InMatch" then
		return player:GetAttribute("MatchParticipant") == true
	end
	return player:GetAttribute("MatchParticipant") ~= false
end

-- Block aim UI unless the held ball is throwable (arena dodgeball or lobby practice).
local function cannotUseThrowInput(): boolean
	if player:GetAttribute("IsOut") == true then
		return true
	end
	if localPlayerHoldsBall() then
		return not canThrowHeldBall()
	end
	local phase = getMatchPhase()
	if phase == "InMatch" then
		return player:GetAttribute("MatchParticipant") ~= true
	end
	if phase == "Lobby" then
		return true
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
	local rayX: number
	local rayY: number
	if aimUsesFreeCursor then
		local mouse = UserInputService:GetMouseLocation()
		local inset = GuiService:GetGuiInset()
		rayX = mouse.X - inset.X
		rayY = mouse.Y - inset.Y
	else
		local viewport = camera.ViewportSize
		rayX = viewport.X * 0.5
		rayY = viewport.Y * 0.5
	end
	local ray = camera:ViewportPointToRay(rayX, rayY)

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
	aimUsesFreeCursor = false
	crosshair.Visible = false
	powerBarBack.Visible = false
	restoreRotationTypeAfterAim()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	stopAimHeartbeat()
end

local function fireThrow(powerRatio: number)
	if not throwRemote then
		if not warnedMissingThrow then
			warnedMissingThrow = true
			warn(`{SCRIPT_TAG} Cannot throw — RequestThrow remote missing. Re-paste DodgeballService.`)
		end
		endAimUi()
		return
	end
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

local function fireStartAiming()
	if localPlayerHoldsLobbyPracticeBall() then
		return
	end
	if startAimingRemote then
		startAimingRemote:FireServer()
	elseif not warnedMissingStartAiming then
		warnedMissingStartAiming = true
		warn(
			`{SCRIPT_TAG} StartAiming remote missing — server may force roll on hold timeout. Re-paste DodgeballService.`
		)
	end
end

local function beginAim(inputObject: InputObject)
	if aiming or cannotUseThrowInput() or not localPlayerHoldsBall() or not canThrowHeldBall() then
		return
	end
	aiming = true
	aimUsesFreeCursor = shouldUseFreeCursorAim(inputObject)
	aimBeganAt = os.clock()
	fireStartAiming()
	holdBallSince = nil
	holdBarBack.Visible = false

	crosshair.Visible = not aimUsesFreeCursor
	powerBarBack.Visible = true
	setPowerUi(0)
	if aimUsesFreeCursor then
		saveRotationTypeForAim()
		applyFreeCursorCameraIndependence()
	else
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
	end

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
local mouseThrowInputConn: RBXScriptConnection? = nil
local mouseThrowReleaseConn: RBXScriptConnection? = nil

local function onThrowAction(_actionName: string, inputState: Enum.UserInputState, inputObject: InputObject)
	if inputState == Enum.UserInputState.Begin then
		beginAim(inputObject)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		endAimAndThrow()
	end
	return Enum.ContextActionResult.Sink
end

-- Free cursor: PlayerModule / UI often win LMB before CAS at Medium; LockCenter hid that. UIS backs up PC mouse hold.
local function connectMouseThrowInputFallback()
	if mouseThrowInputConn or mouseThrowReleaseConn then
		return
	end
	if not UserInputService.MouseEnabled then
		return
	end

	mouseThrowInputConn = UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if not shouldUseFreeCursorAim(input) then
			return
		end
		if gameProcessed and (not localPlayerHoldsBall() or not canThrowHeldBall()) then
			return
		end
		beginAim(input)
	end)

	mouseThrowReleaseConn = UserInputService.InputEnded:Connect(function(input: InputObject, _gameProcessed: boolean)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
			return
		end
		if aiming and aimUsesFreeCursor then
			endAimAndThrow()
		end
	end)
end

local function bindThrowAction()
	if throwActionBound then
		return
	end
	throwActionBound = true
	local priority = Enum.ContextActionPriority.High.Value
	local casInputs: { Enum.KeyCode | Enum.UserInputType } = {
		Enum.KeyCode.F,
		Enum.KeyCode.ButtonR2,
	}
	local touchOnly = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	if touchOnly then
		table.insert(casInputs, Enum.UserInputType.MouseButton1)
	elseif UserInputService.TouchEnabled then
		table.insert(casInputs, Enum.UserInputType.Touch)
	end
	ContextActionService:BindActionAtPriority(ACTION_THROW_AIM, onThrowAction, false, priority, table.unpack(casInputs))
	if UserInputService.MouseEnabled then
		connectMouseThrowInputFallback()
	end
end

bindThrowAction()

RunService:BindToRenderStep(FREE_CURSOR_CAMERA_BIND, Enum.RenderPriority.Camera.Value + 1, function()
	if aiming and aimUsesFreeCursor then
		applyFreeCursorCameraIndependence()
	end
end)

RunService.RenderStepped:Connect(function()
	if localPlayerHoldsLobbyPracticeBall() then
		holdBallSince = nil
		holdBarBack.Visible = false
	end
	if aiming or cannotUseThrowInput() then
		if not aiming and holdBarBack.Visible then
			holdBarBack.Visible = false
			holdBallSince = nil
		end
		return
	end

	local holds = localPlayerHoldsBall() and canThrowHeldBall() and not localPlayerHoldsLobbyPracticeBall()
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

local function endAimIfNoLongerAllowed()
	if aiming and not canThrowHeldBall() then
		endAimUi()
	end
	if cannotUseThrowInput() then
		holdBallSince = nil
		holdBarBack.Visible = false
	end
end

player:GetAttributeChangedSignal("IsOut"):Connect(endAimIfNoLongerAllowed)
player:GetAttributeChangedSignal("MatchParticipant"):Connect(endAimIfNoLongerAllowed)

local roundStatus = ReplicatedStorage:WaitForChild(ROUND_STATUS_FOLDER, 5)
if roundStatus and roundStatus:IsA("Folder") then
	roundStatus:GetAttributeChangedSignal("MatchPhase"):Connect(endAimIfNoLongerAllowed)
end
