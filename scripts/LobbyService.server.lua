-- Paste as Script named LobbyService under ServerScriptService (with RoundService + DodgeballService).
-- Phases: Lobby (countdown, neutral spawn) → InMatch (arena rounds, first to MATCH_POINTS_TO_WIN).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local PHASE_LOBBY = "Lobby"
local PHASE_IN_MATCH = "InMatch"

local matchPhase: string = PHASE_LOBBY
local matchScores: { [string]: number } = {}
local lobbyCountdownEndsAt: number? = nil
local countdownPaused = true

local function initMatchScores()
	matchScores = {}
	for _, teamName in Config.TEAM_NAMES do
		if typeof(teamName) == "string" then
			matchScores[teamName] = 0
		end
	end
end

initMatchScores()

local function getOrCreateRoundStatusFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Config.ROUND_STATUS_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.ROUND_STATUS_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local roundStatus = getOrCreateRoundStatusFolder()

local function publishMatchStatus()
	roundStatus:SetAttribute("MatchPhase", matchPhase)
	for teamName, score in matchScores do
		roundStatus:SetAttribute(`MatchScore_{teamName}`, score)
	end
	roundStatus:SetAttribute("MatchPointsToWin", Config.MATCH_POINTS_TO_WIN)
	if lobbyCountdownEndsAt then
		roundStatus:SetAttribute("LobbyCountdownEndsAt", lobbyCountdownEndsAt)
	else
		roundStatus:SetAttribute("LobbyCountdownEndsAt", nil)
	end
end

local function findLobbySpawnLocation(): SpawnLocation?
	local name = Config.LOBBY_SPAWN_NAME
	if typeof(name) == "string" and name ~= "" then
		for _, descendant in Workspace:GetDescendants() do
			if descendant:IsA("SpawnLocation") and descendant.Name == name then
				return descendant
			end
		end
	end
	local tag = Config.LOBBY_SPAWN_TAG
	if typeof(tag) == "string" and tag ~= "" then
		for _, inst in CollectionService:GetTagged(tag) do
			if inst:IsA("SpawnLocation") then
				return inst
			end
		end
	end
	return nil
end

local function respawnPlayerAtLobby(player: Player)
	player.Team = nil
	player.Neutral = true
	player:LoadCharacter()
	local spawn = findLobbySpawnLocation()
	local character = player.Character
	if spawn and character then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = spawn.CFrame + Vector3.new(0, 4, 0)
		end
	end
end

local function respawnAllAtLobby()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("IsOut", false)
		player.CharacterAutoLoads = true
		respawnPlayerAtLobby(player)
	end
end

local function countPlayers(): number
	return #Players:GetPlayers()
end

local function resetLobbyCountdownFull()
	lobbyCountdownEndsAt = nil
	countdownPaused = true
	publishMatchStatus()
end

local function ensureLobbyCountdownRunning()
	if matchPhase ~= PHASE_LOBBY then
		return
	end
	if countPlayers() < 2 then
		resetLobbyCountdownFull()
		return
	end
	if countdownPaused or not lobbyCountdownEndsAt then
		countdownPaused = false
		lobbyCountdownEndsAt = workspace:GetServerTimeNow() + Config.LOBBY_COUNTDOWN_SECONDS
		publishMatchStatus()
		warn(`[LobbyService] Lobby countdown started ({Config.LOBBY_COUNTDOWN_SECONDS}s) — waiting for match start.`)
	end
end

local function enterLobbyPhase(reason: string)
	matchPhase = PHASE_LOBBY
	initMatchScores()
	resetLobbyCountdownFull()
	publishMatchStatus()
	warn(`[LobbyService] Lobby phase ({reason}). First to {Config.MATCH_POINTS_TO_WIN} round wins takes the match.`)
	task.defer(respawnAllAtLobby)
	task.defer(ensureLobbyCountdownRunning)
end

local function invokeBridge(functionName: string): boolean
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if not bridge then
		return false
	end
	local bindable = bridge:FindFirstChild(functionName)
	if bindable and bindable:IsA("BindableFunction") then
		local ok, result = pcall(function()
			return (bindable :: BindableFunction):Invoke()
		end)
		if not ok then
			warn(`[LobbyService] {functionName} failed: {result}`)
			return false
		end
		return result == true
	end
	warn(`[LobbyService] Missing BindableFunction {functionName}. Is TeamAutoBalance loaded?`)
	return false
end

local function startMatchFromLobby()
	if countPlayers() < 2 then
		resetLobbyCountdownFull()
		return
	end
	matchPhase = PHASE_IN_MATCH
	lobbyCountdownEndsAt = nil
	countdownPaused = true
	publishMatchStatus()
	warn("[LobbyService] Match started — teams to arena spawns!")

	invokeBridge("AssignMatchTeams")

	for _, player in Players:GetPlayers() do
		player.Neutral = false
		player.CharacterAutoLoads = true
		player:SetAttribute("IsOut", false)
		player:LoadCharacter()
	end

	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if bridge then
		local ev = bridge:FindFirstChild("BeginMatchRound")
		if ev and ev:IsA("BindableEvent") then
			ev:Fire()
		end
	end
end

local function onLobbyTick()
	if matchPhase ~= PHASE_LOBBY then
		return
	end

	local n = countPlayers()
	if n < 2 then
		if not countdownPaused or lobbyCountdownEndsAt ~= nil then
			warn("[LobbyService] Only 1 player — lobby countdown paused and reset.")
			resetLobbyCountdownFull()
		end
		return
	end

	ensureLobbyCountdownRunning()

	if lobbyCountdownEndsAt and workspace:GetServerTimeNow() >= lobbyCountdownEndsAt then
		startMatchFromLobby()
	end
end

local function awardMatchPoint(winningTeam: Team): boolean
	local name = winningTeam.Name
	local current = matchScores[name] or 0
	matchScores[name] = current + 1
	publishMatchStatus()
	warn(`[LobbyService] Match point — {name} now {matchScores[name]} / {Config.MATCH_POINTS_TO_WIN}.`)
	return (matchScores[name] or 0) >= Config.MATCH_POINTS_TO_WIN
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

local function wireRoundBridge()
	local bridge = ensureRoundBridge()

	local notifyFn = bridge:FindFirstChild("NotifyRoundWin")
	if not notifyFn then
		notifyFn = Instance.new("BindableFunction")
		notifyFn.Name = "NotifyRoundWin"
		notifyFn.Parent = bridge
	end

	(notifyFn :: BindableFunction).OnInvoke = function(winningTeam: Instance?): boolean
		if matchPhase ~= PHASE_IN_MATCH then
			return true
		end
		if not winningTeam or not winningTeam:IsA("Team") then
			return true
		end
		local matchOver = awardMatchPoint(winningTeam)
		if matchOver then
			warn(`[LobbyService] {winningTeam.Name} wins the match!`)
			task.defer(function()
				enterLobbyPhase("match won")
			end)
			return false
		end
		return true
	end

	local beginEv = bridge:FindFirstChild("BeginMatchRound")
	if not beginEv then
		beginEv = Instance.new("BindableEvent")
		beginEv.Name = "BeginMatchRound"
		beginEv.Parent = bridge
	end
end

local function onPlayerAdded(player: Player)
	if matchPhase == PHASE_LOBBY then
		task.defer(function()
			if player.Parent and matchPhase == PHASE_LOBBY then
				respawnPlayerAtLobby(player)
				ensureLobbyCountdownRunning()
			end
		end)
	elseif matchPhase == PHASE_IN_MATCH then
		invokeBridge("AssignMatchTeams")
		player.Neutral = false
		player:SetAttribute("IsOut", false)
		player.CharacterAutoLoads = true
		player:LoadCharacter()
	end
end

local function onPlayerRemoving()
	if matchPhase == PHASE_LOBBY and countPlayers() - 1 < 2 then
		task.defer(resetLobbyCountdownFull)
	end
end

Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

for _, player in Players:GetPlayers() do
	task.defer(function()
		onPlayerAdded(player)
	end)
end

wireRoundBridge()
publishMatchStatus()
enterLobbyPhase("server start")

task.spawn(function()
	while true do
		onLobbyTick()
		task.wait(0.25)
	end
end)