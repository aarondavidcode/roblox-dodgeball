-- Paste as LocalScript named LobbyJoinNextMatchClient under StarterPlayerScripts.
-- Builds ScreenGui "JoinNextMatch" (BottomBar: OptInToggle + one-time QueueHint) at run time.

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

-- Keep in sync with DodgeballConfig (ModuleScript lives under ServerScriptService).
local ATTR_JOIN = "JoinNextMatch"
local REMOTE_NAME = "SetJoinNextMatch"
local REMOTES_FOLDER = "DodgeballRemotes"
local ROUND_STATUS_FOLDER = "RoundStatus"

local HINT_VISIBLE_SECONDS = 30
local HINT_FADE_SECONDS = 2
local BAR_HEIGHT = 44

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer:WaitForChild("PlayerGui")

local remotes = ReplicatedStorage:WaitForChild(REMOTES_FOLDER, 30)
if not remotes then
	warn("[LobbyJoinNextMatchClient] DodgeballRemotes missing — is LobbyService running?")
	return
end

local setJoinRemote = remotes:WaitForChild(REMOTE_NAME, 15) :: RemoteEvent?
if not setJoinRemote then
	warn(`[LobbyJoinNextMatchClient] Remote {REMOTE_NAME} missing.`)
	return
end

local roundStatus = ReplicatedStorage:WaitForChild(ROUND_STATUS_FOLDER, 30)

local hintSessionEnded = false
local hintTimerStarted = false
local hintFadeInProgress = false
local hintTimerGeneration = 0

local function ensureGui(): (ScreenGui, TextButton, Frame)
	local existing = playerGui:FindFirstChild("JoinNextMatch")
	if existing and existing:IsA("ScreenGui") then
		local bar = existing:FindFirstChild("BottomBar")
		if bar and bar:IsA("Frame") then
			local btn = bar:FindFirstChild("OptInToggle")
			local hint = bar:FindFirstChild("QueueHint")
			if btn and btn:IsA("TextButton") and hint and hint:IsA("Frame") then
				return existing, btn, hint
			end
		end
		existing:Destroy()
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JoinNextMatch"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local bottomBar = Instance.new("Frame")
	bottomBar.Name = "BottomBar"
	bottomBar.AnchorPoint = Vector2.new(0.5, 1)
	bottomBar.Position = UDim2.fromScale(0.5, 0.92)
	bottomBar.Size = UDim2.fromOffset(0, BAR_HEIGHT)
	bottomBar.AutomaticSize = Enum.AutomaticSize.X
	bottomBar.BackgroundTransparency = 1
	bottomBar.Parent = screenGui

	local barLayout = Instance.new("UIListLayout")
	barLayout.FillDirection = Enum.FillDirection.Horizontal
	barLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	barLayout.SortOrder = Enum.SortOrder.LayoutOrder
	barLayout.Padding = UDim.new(0, 8)
	barLayout.Parent = bottomBar

	local button = Instance.new("TextButton")
	button.Name = "OptInToggle"
	button.LayoutOrder = 1
	button.Size = UDim2.fromOffset(0, BAR_HEIGHT)
	button.AutomaticSize = Enum.AutomaticSize.X
	button.TextWrapped = false
	button.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "Joining next match"
	button.Parent = bottomBar

	local buttonPadding = Instance.new("UIPadding")
	buttonPadding.PaddingLeft = UDim.new(0, 16)
	buttonPadding.PaddingRight = UDim.new(0, 16)
	buttonPadding.Parent = button

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	local queueHint = Instance.new("Frame")
	queueHint.Name = "QueueHint"
	queueHint.LayoutOrder = 2
	queueHint.Size = UDim2.fromOffset(0, BAR_HEIGHT)
	queueHint.AutomaticSize = Enum.AutomaticSize.X
	queueHint.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
	queueHint.BackgroundTransparency = 0.15
	queueHint.BorderSizePixel = 0
	queueHint.Visible = false
	queueHint.Active = true
	queueHint.Parent = bottomBar

	local hintCorner = Instance.new("UICorner")
	hintCorner.CornerRadius = UDim.new(0, 10)
	hintCorner.Parent = queueHint

	local hintLayout = Instance.new("UIListLayout")
	hintLayout.FillDirection = Enum.FillDirection.Horizontal
	hintLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hintLayout.SortOrder = Enum.SortOrder.LayoutOrder
	hintLayout.Padding = UDim.new(0, 4)
	hintLayout.Parent = queueHint

	local hintPadding = Instance.new("UIPadding")
	hintPadding.PaddingLeft = UDim.new(0, 10)
	hintPadding.PaddingRight = UDim.new(0, 14)
	hintPadding.Parent = queueHint

	local arrow = Instance.new("TextLabel")
	arrow.Name = "Arrow"
	arrow.LayoutOrder = 1
	arrow.BackgroundTransparency = 1
	arrow.Size = UDim2.fromOffset(16, BAR_HEIGHT)
	arrow.Font = Enum.Font.GothamBold
	arrow.TextSize = 20
	arrow.TextColor3 = Color3.fromRGB(255, 220, 120)
	arrow.Text = "◀"
	arrow.TextXAlignment = Enum.TextXAlignment.Right
	arrow.Active = true
	arrow.Parent = queueHint

	local hintLabel = Instance.new("TextLabel")
	hintLabel.Name = "HintText"
	hintLabel.LayoutOrder = 2
	hintLabel.BackgroundTransparency = 1
	hintLabel.Size = UDim2.fromOffset(0, BAR_HEIGHT)
	hintLabel.AutomaticSize = Enum.AutomaticSize.X
	hintLabel.Font = Enum.Font.GothamMedium
	hintLabel.TextSize = 16
	hintLabel.TextColor3 = Color3.new(1, 1, 1)
	hintLabel.TextWrapped = false
	hintLabel.Text = "Tap here to queue or spectate"
	hintLabel.Active = true
	hintLabel.Parent = queueHint

	return screenGui, button, queueHint
end

local screenGui, toggleButton, queueHint = ensureGui()

local function optedIn(): boolean
	return localPlayer:GetAttribute(ATTR_JOIN) ~= false
end

local function isQualifyingNeutral(): boolean
	if not roundStatus then
		return false
	end
	local matchPhase = roundStatus:GetAttribute("MatchPhase")
	if matchPhase ~= "Lobby" and matchPhase ~= "InMatch" then
		return false
	end
	if localPlayer:GetAttribute("MatchParticipant") == true then
		return false
	end
	if localPlayer.Team ~= nil then
		return false
	end
	if not localPlayer.Neutral then
		return false
	end
	if matchPhase == "InMatch" and localPlayer:GetAttribute("IsOut") == true then
		return false
	end
	return true
end

local function refreshButtonVisual()
	if optedIn() then
		toggleButton.BackgroundColor3 = Color3.fromRGB(40, 150, 85)
		toggleButton.Text = "Joining next match"
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
		toggleButton.Text = "Spectating"
	end
end

local function finalizeHintSession()
	hintSessionEnded = true
	queueHint.Visible = false
end

local function playHintFadeOut()
	local fadeInfo = TweenInfo.new(HINT_FADE_SECONDS, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweens: { Tween } = {}
	table.insert(tweens, TweenService:Create(queueHint, fadeInfo, { BackgroundTransparency = 1 }))
	for _, desc in queueHint:GetDescendants() do
		if desc:IsA("TextLabel") then
			table.insert(
				tweens,
				TweenService:Create(desc, fadeInfo, { TextTransparency = 1, BackgroundTransparency = 1 })
			)
		end
	end
	for _, tween in tweens do
		tween:Play()
	end
end

local function startHintFadeOut()
	if hintSessionEnded or hintFadeInProgress or not queueHint.Visible then
		return
	end
	hintFadeInProgress = true
	playHintFadeOut()
	task.delay(HINT_FADE_SECONDS, function()
		if not hintFadeInProgress then
			return
		end
		hintFadeInProgress = false
		finalizeHintSession()
	end)
end

local function dismissHintFromTap()
	if hintSessionEnded or hintFadeInProgress then
		return
	end
	if not hintTimerStarted or not queueHint.Visible then
		return
	end
	hintTimerGeneration += 1
	startHintFadeOut()
end

local function wireHintDismissInput()
	local function onHintPointer(input: InputObject)
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		dismissHintFromTap()
	end
	queueHint.InputBegan:Connect(onHintPointer)
	for _, desc in queueHint:GetDescendants() do
		if desc:IsA("GuiObject") then
			desc.InputBegan:Connect(onHintPointer)
		end
	end
end

local function maybeStartHintTimer()
	if hintSessionEnded or hintTimerStarted or not isQualifyingNeutral() then
		return
	end
	hintTimerStarted = true
	queueHint.Visible = true
	queueHint.BackgroundTransparency = 0.15
	for _, desc in queueHint:GetDescendants() do
		if desc:IsA("TextLabel") then
			desc.TextTransparency = 0
			desc.BackgroundTransparency = 1
		end
	end

	hintTimerGeneration += 1
	local generation = hintTimerGeneration

	task.delay(HINT_VISIBLE_SECONDS - HINT_FADE_SECONDS, function()
		if hintSessionEnded or generation ~= hintTimerGeneration then
			return
		end
		startHintFadeOut()
	end)
end

wireHintDismissInput()

local function refreshHintVisibility()
	if hintSessionEnded then
		queueHint.Visible = false
		return
	end
	if not hintTimerStarted then
		queueHint.Visible = false
		return
	end
	queueHint.Visible = isQualifyingNeutral()
end

local function refreshVisibility()
	local show = isQualifyingNeutral()
	screenGui.Enabled = show
	if show then
		refreshButtonVisual()
		maybeStartHintTimer()
	end
	refreshHintVisibility()
end

toggleButton.Activated:Connect(function()
	dismissHintFromTap()
	if not isQualifyingNeutral() then
		return
	end
	setJoinRemote:FireServer(not optedIn())
end)

localPlayer:GetAttributeChangedSignal(ATTR_JOIN):Connect(function()
	refreshButtonVisual()
	refreshVisibility()
end)

localPlayer:GetPropertyChangedSignal("Team"):Connect(refreshVisibility)
localPlayer:GetPropertyChangedSignal("Neutral"):Connect(refreshVisibility)
localPlayer:GetAttributeChangedSignal("MatchParticipant"):Connect(refreshVisibility)

if roundStatus then
	roundStatus:GetAttributeChangedSignal("MatchPhase"):Connect(function()
		refreshVisibility()
		refreshButtonVisual()
	end)
end

refreshVisibility()