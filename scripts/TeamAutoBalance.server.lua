-- Paste this as a Script named TeamAutoBalance under ServerScriptService.
-- Teams in your place must be named exactly Red and Blue (see TEAM_NAMES below).
-- During lobby (MatchPhase "Lobby" on RoundStatus), players stay Neutral with no team.
-- Red/Blue assignment runs when a match starts (LobbyService AssignMatchTeams).
-- Mid-match joiners stay Neutral at the lobby pad (MatchParticipant false) until the match ends.

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local StarterPlayer = game:GetService("StarterPlayer")
local Teams = game:GetService("Teams")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local MATCH_PHASE_IN_MATCH = "InMatch"
local ATTR_MATCH_PARTICIPANT = "MatchParticipant"
local ATTR_JOIN_NEXT_MATCH = Config.JOIN_NEXT_MATCH_ATTR

local TEAM_NAMES = Config.TEAM_NAMES

local TEAM_WAIT_SECONDS = 10

local redTeam: Team?
local blueTeam: Team?

local usedSpawnSafetyNet: { [Player]: boolean } = {}

local function getRoundStatusFolder(): Folder?
	local existing = ReplicatedStorage:FindFirstChild(Config.ROUND_STATUS_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	return nil
end

local function getMatchPhase(): string
	local folder = getRoundStatusFolder()
	if folder then
		local matchPhase = folder:GetAttribute("MatchPhase")
		if typeof(matchPhase) == "string" then
			return matchPhase
		end
	end
	return "Lobby"
end

local function matchIsLive(): boolean
	return getMatchPhase() == MATCH_PHASE_IN_MATCH
end

local function isMatchParticipant(player: Player): boolean
	return player:GetAttribute(ATTR_MATCH_PARTICIPANT) == true
end

local function setSpectatorNeutral(player: Player)
	player.Neutral = true
	player.Team = nil
end

local function waitForTeams(): boolean
	local red = Teams:WaitForChild(TEAM_NAMES[1], TEAM_WAIT_SECONDS)
	if not red or not red:IsA("Team") then
		warn(
			`[TeamAutoBalance] Missing Team named "{TEAM_NAMES[1]}" after {TEAM_WAIT_SECONDS}s. Check Explorer → Teams (spelling and capitals).`
		)
		return false
	end

	local blue = Teams:WaitForChild(TEAM_NAMES[2], TEAM_WAIT_SECONDS)
	if not blue or not blue:IsA("Team") then
		warn(
			`[TeamAutoBalance] Missing Team named "{TEAM_NAMES[2]}" after {TEAM_WAIT_SECONDS}s. Check Explorer → Teams (spelling and capitals).`
		)
		return false
	end

	redTeam = red
	blueTeam = blue
	return true
end

local function teamsReady(): boolean
	if not redTeam or not blueTeam then
		warn("[TeamAutoBalance] Red or Blue team is not ready yet. Check Teams in Explorer.")
		return false
	end
	if redTeam == blueTeam then
		warn("[TeamAutoBalance] Red and Blue resolved to the same Team instance — fix Explorer → Teams.")
		return false
	end
	return true
end

local function sortedPlayers(): { Player }
	local list = Players:GetPlayers()
	table.sort(list, function(a: Player, b: Player)
		return a.UserId < b.UserId
	end)
	return list
end

local function maybeLoadCharacter(player: Player, needsRespawn: boolean)
	if matchIsLive() and player:GetAttribute("IsOut") == true then
		return
	end
	local shouldLoad = needsRespawn
	if not player.Character and not StarterPlayer.CharacterAutoLoads then
		shouldLoad = true
	end
	if shouldLoad and matchIsLive() and player:GetAttribute("IsOut") == true then
		return
	end
	if shouldLoad then
		player:LoadCharacter()
	end
end

-- Deterministic batch balance: sort by UserId, assign each to the smaller team count.
local function assignAllPlayersBalanced(needsRespawn: boolean): boolean
	if not teamsReady() then
		return false
	end

	local redCount = 0
	local blueCount = 0

	for _, player in sortedPlayers() do
		if matchIsLive() and player:GetAttribute(ATTR_MATCH_PARTICIPANT) == false then
			continue
		end
		if matchIsLive() and not isMatchParticipant(player) then
			if player:GetAttribute(ATTR_JOIN_NEXT_MATCH) ~= true then
				continue
			end
		end
		local chosenTeam: Team
		if redCount <= blueCount then
			chosenTeam = redTeam :: Team
			redCount += 1
		else
			chosenTeam = blueTeam :: Team
			blueCount += 1
		end

		player.Neutral = false
		player.Team = chosenTeam
		warn(`[TeamAutoBalance] Match teams: {player.Name} (UserId {player.UserId}) → {chosenTeam.Name}`)
		maybeLoadCharacter(player, needsRespawn)
	end

	warn(`[TeamAutoBalance] Final counts — Red: {redCount}, Blue: {blueCount}`)
	return true
end

local function assignBalancedTeam(player: Player, needsRespawn: boolean)
	assignAllPlayersBalanced(false)
	if needsRespawn then
		maybeLoadCharacter(player, true)
	end
end

local function setLobbyNeutral(player: Player)
	if matchIsLive() then
		return
	end
	player.Neutral = true
	player.Team = nil
end

local function neutralizeAllPlayers()
	for _, player in Players:GetPlayers() do
		setLobbyNeutral(player)
	end
end

local function trySpawnSafetyNet(player: Player)
	-- InMatch round resets: LobbyService teleports to team pads; never strip team or force lobby here.
	if matchIsLive() then
		if not isMatchParticipant(player) then
			if player.Team ~= nil or not player.Neutral then
				setSpectatorNeutral(player)
			end
			return
		end
		if player.Team ~= nil and not player.Neutral then
			return
		end
		if player:GetAttribute("IsOut") == true then
			return
		end
		if usedSpawnSafetyNet[player] then
			return
		end
		usedSpawnSafetyNet[player] = true
		assignBalancedTeam(player, true)
		return
	end

	if player.Team ~= nil or not player.Neutral then
		if usedSpawnSafetyNet[player] then
			return
		end
		usedSpawnSafetyNet[player] = true
		setLobbyNeutral(player)
	end
end

local function hookCharacterAdded(player: Player)
	player.CharacterAdded:Connect(function()
		trySpawnSafetyNet(player)
	end)
end

local function onPlayerAdded(player: Player)
	hookCharacterAdded(player)

	if matchIsLive() then
		if isMatchParticipant(player) then
			assignBalancedTeam(player, player.Character ~= nil)
		else
			setSpectatorNeutral(player)
		end
	else
		setLobbyNeutral(player)
	end
end

local function onMatchPhaseChanged()
	if matchIsLive() then
		-- Team assignment is triggered by LobbyService via AssignMatchTeams (after phase publish).
		return
	end
	neutralizeAllPlayers()
end

local function wireRoundBridge()
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if not bridge or not bridge:IsA("Folder") then
		bridge = Instance.new("Folder")
		bridge.Name = "DodgeballRoundBridge"
		bridge.Parent = ServerScriptService
	end

	local assignFn = bridge:FindFirstChild("AssignMatchTeams")
	if not assignFn then
		assignFn = Instance.new("BindableFunction")
		assignFn.Name = "AssignMatchTeams"
		assignFn.Parent = bridge
	end

	(assignFn :: BindableFunction).OnInvoke = function(): boolean
		return assignAllPlayersBalanced(false)
	end
end

local function hookMatchPhaseSignal()
	local folder = getRoundStatusFolder()
	if not folder then
		local deadline = os.clock() + 15
		while os.clock() < deadline do
			folder = getRoundStatusFolder()
			if folder then
				break
			end
			task.wait(0.1)
		end
	end
	if folder then
		folder:GetAttributeChangedSignal("MatchPhase"):Connect(onMatchPhaseChanged)
	end
end

Players.PlayerRemoving:Connect(function(player)
	usedSpawnSafetyNet[player] = nil
end)

if not waitForTeams() then
	warn("[TeamAutoBalance] Stopping — create teams named Red and Blue, then play again.")
	return
end

wireRoundBridge()
hookMatchPhaseSignal()

Players.PlayerAdded:Connect(onPlayerAdded)

for _, player in Players:GetPlayers() do
	task.defer(function()
		onPlayerAdded(player)
	end)
end

if not matchIsLive() then
	neutralizeAllPlayers()
end