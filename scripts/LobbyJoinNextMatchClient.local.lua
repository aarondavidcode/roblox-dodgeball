-- Paste as LocalScript named LobbyJoinNextMatchClient under StarterPlayerScripts.
-- Builds ScreenGui "JoinNextMatch" with toggle button "OptInToggle" at run time.

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Keep in sync with DodgeballConfig (ModuleScript lives under ServerScriptService).
local ATTR_JOIN = "JoinNextMatch"
local REMOTE_NAME = "SetJoinNextMatch"
local REMOTES_FOLDER = "DodgeballRemotes"
local ROUND_STATUS_FOLDER = "RoundStatus"

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

local function ensureGui(): (ScreenGui, TextButton)
	local existing = playerGui:FindFirstChild("JoinNextMatch")
	if existing and existing:IsA("ScreenGui") then
		local btn = existing:FindFirstChild("OptInToggle")
		if btn and btn:IsA("TextButton") then
			return existing, btn
		end
	end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "JoinNextMatch"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local button = Instance.new("TextButton")
	button.Name = "OptInToggle"
	button.AnchorPoint = Vector2.new(0.5, 1)
	button.Position = UDim2.fromScale(0.5, 0.92)
	button.Size = UDim2.fromOffset(280, 44)
	button.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.GothamBold
	button.TextSize = 18
	button.TextColor3 = Color3.new(1, 1, 1)
	button.Text = "Play next match — tap to join!"
	button.Parent = screenGui

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = button

	return screenGui, button
end

local screenGui, toggleButton = ensureGui()

local function optedIn(): boolean
	-- Server default is opted in; only explicit false opts out.
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
	local inLiveMatch = false
	if roundStatus then
		inLiveMatch = roundStatus:GetAttribute("MatchPhase") == "InMatch"
	end
	if optedIn() then
		toggleButton.BackgroundColor3 = Color3.fromRGB(40, 150, 85)
		if inLiveMatch then
			toggleButton.Text = "Next match after this one — tap to spectate"
		else
			toggleButton.Text = "Joined next match — tap to spectate"
		end
	else
		toggleButton.BackgroundColor3 = Color3.fromRGB(45, 120, 200)
		if inLiveMatch then
			toggleButton.Text = "Join the match after this one — tap here"
		else
			toggleButton.Text = "Play next match — tap to join!"
		end
	end
end

local function refreshVisibility()
	local show = isQualifyingNeutral()
	screenGui.Enabled = show
	if show then
		refreshButtonVisual()
	end
end

toggleButton.Activated:Connect(function()
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