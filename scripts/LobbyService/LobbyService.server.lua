-- Studio setup: LobbyService.md
-- Paste as Script named LobbyService under ServerScriptService (with RoundService + DodgeballService).
-- Phases: Lobby (countdown, neutral spawn) → InMatch (arena rounds, first to MATCH_POINTS_TO_WIN).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local PHASE_LOBBY = "Lobby"
local PHASE_IN_MATCH = "InMatch"

local ATTR_MATCH_PARTICIPANT = "MatchParticipant"
local ATTR_JOIN_NEXT_MATCH = Config.JOIN_NEXT_MATCH_ATTR

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

local function playerJoinNextMatchOptedIn(player: Player): boolean
	-- Default opted in: only explicit false opts out (nil counts as in).
	return player:GetAttribute(ATTR_JOIN_NEXT_MATCH) ~= false
end

local function countOptedInPlayers(): number
	local n = 0
	for _, player in Players:GetPlayers() do
		if playerJoinNextMatchOptedIn(player) then
			n += 1
		end
	end
	return n
end

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
	roundStatus:SetAttribute("LobbyOptedInCount", countOptedInPlayers())
end

local SPAWN_Y_OFFSET = 4

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

-- Roblox LoadCharacter() picks SpawnLocation by TeamColor match; names like RedSpawn/BlueSpawn are fine.
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

local function arenaSpawnCFrame(teamSpawn: SpawnLocation, opposingSpawn: SpawnLocation?): CFrame
	local pos = teamSpawn.CFrame.Position + Vector3.new(0, SPAWN_Y_OFFSET, 0)
	if opposingSpawn then
		local target = opposingSpawn.CFrame.Position
		local lookAt = Vector3.new(target.X, pos.Y, target.Z)
		if (lookAt - pos).Magnitude > 0.5 then
			return CFrame.lookAt(pos, lookAt)
		end
	end
	return teamSpawn.CFrame + Vector3.new(0, SPAWN_Y_OFFSET, 0)
end

local function loadCharacterIfAllowed(player: Player, context: string): boolean
	if player:GetAttribute("IsOut") == true then
		warn(`[LobbyService] Blocked LoadCharacter for {player.Name} — still OUT ({context}).`)
		return false
	end
	player:LoadCharacter()
	return true
end

local function isMatchParticipant(player: Player): boolean
	return player:GetAttribute(ATTR_MATCH_PARTICIPANT) == true
end

local function clearAllMatchParticipants()
	for _, player in Players:GetPlayers() do
		player:SetAttribute(ATTR_MATCH_PARTICIPANT, nil)
	end
end

local function teleportCharacterToTeamSpawn(player: Player)
	if not isMatchParticipant(player) then
		return
	end
	local team = player.Team
	if not team then
		return
	end
	local spawn = findTeamSpawnLocation(team)
	if not spawn then
		warn(
			`[LobbyService] No arena SpawnLocation for {team.Name} — on your team pad set Neutral off and TeamColor to match Teams → {team.Name}. Pad names like RedSpawn/BlueSpawn are OK.`
		)
		return
	end
	local character = player.Character
	if not character then
		character = player.CharacterAdded:Wait()
	end
	if not player.Parent or matchPhase ~= PHASE_IN_MATCH then
		return
	end
	local hrp = character:WaitForChild("HumanoidRootPart", 10) :: BasePart?
	if hrp then
		local opposingSpawn = findOpposingTeamSpawnLocation(team)
		hrp.CFrame = arenaSpawnCFrame(spawn, opposingSpawn)
		warn(`[LobbyService] {player.Name} placed on {spawn.Name} facing {team.Name} vs opponents.`)
	end
end

-- Match start and between-round reset: LoadCharacter then force team pad (survivors often miss TeamColor spawns).
local function spawnPlayerAtTeamArena(player: Player)
	if matchPhase ~= PHASE_IN_MATCH then
		warn(
			`[LobbyService] spawnPlayerAtTeamArena skipped for {player.Name} — MatchPhase is {matchPhase}, not InMatch.`
		)
		return
	end
	if not isMatchParticipant(player) then
		return
	end
	if not player.Team then
		warn(`[LobbyService] spawnPlayerAtTeamArena skipped for {player.Name} — no team.`)
		return
	end
	player.Neutral = false
	if not loadCharacterIfAllowed(player, "spawnPlayerAtTeamArena") then
		return
	end
	teleportCharacterToTeamSpawn(player)
end

local function respawnAllPlayersAtTeamArena()
	if matchPhase ~= PHASE_IN_MATCH then
		warn("[LobbyService] respawnAllPlayersAtTeamArena skipped — not InMatch.")
		return
	end
	local playerList = Players:GetPlayers()
	table.sort(playerList, function(a, b)
		return a.UserId < b.UserId
	end)
	for _, player in playerList do
		if not isMatchParticipant(player) or not player.Team then
			continue
		end
		if player:GetAttribute("IsOut") == true then
			warn(`[LobbyService] Skipping arena respawn for {player.Name} — still OUT (wait for ClearAllOuts).`)
			continue
		end
		spawnPlayerAtTeamArena(player)
	end
end

local function teleportCharacterToLobbySpawn(player: Player)
	local spawn = findLobbySpawnLocation()
	local character = player.Character
	if not character then
		return
	end
	if spawn then
		local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if hrp then
			hrp.CFrame = spawn.CFrame + Vector3.new(0, SPAWN_Y_OFFSET, 0)
		end
	end
end

-- Fallback B: OUT player got a stray character mid-match — lobby sideline, no team arena, still IsOut.
local function sidelineOutCharacterAtLobby(player: Player)
	if matchPhase ~= PHASE_IN_MATCH then
		return
	end
	if player:GetAttribute("IsOut") ~= true or not isMatchParticipant(player) then
		return
	end
	local character = player.Character
	if not character then
		return
	end
	teleportCharacterToLobbySpawn(player)
	warn(`[LobbyService] {player.Name} (OUT) sidelined to lobby — no throw until round reset.`)
end

local function respawnPlayerAtLobby(player: Player)
	if matchPhase == PHASE_IN_MATCH and isMatchParticipant(player) then
		return
	end
	player.Team = nil
	player.Neutral = true
	player:LoadCharacter()
	teleportCharacterToLobbySpawn(player)
end

local function respawnSpectatorAtLobby(player: Player)
	player:SetAttribute(ATTR_MATCH_PARTICIPANT, false)
	player:SetAttribute("IsOut", false)
	player.Team = nil
	player.Neutral = true
	player:LoadCharacter()
	teleportCharacterToLobbySpawn(player)
	warn(`[LobbyService] {player.Name} joined mid-match — staying at lobby as spectator until this match ends.`)
end

local function respawnAllAtLobby()
	for _, player in Players:GetPlayers() do
		player:SetAttribute("IsOut", false)
		respawnPlayerAtLobby(player)
	end
end

local function countPlayers(): number
	return #Players:GetPlayers()
end

local function ensureRemotesFolder(): Folder
	local existing = ReplicatedStorage:FindFirstChild(Config.REMOTES_FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = Config.REMOTES_FOLDER_NAME
	folder.Parent = ReplicatedStorage
	return folder
end

local function getSetJoinNextMatchRemote(): RemoteEvent
	local folder = ensureRemotesFolder()
	local name = Config.SET_JOIN_NEXT_MATCH_REMOTE_NAME
	local remote = folder:FindFirstChild(name)
	if remote and remote:IsA("RemoteEvent") then
		return remote
	end
	local newRemote = Instance.new("RemoteEvent")
	newRemote.Name = name
	newRemote.Parent = folder
	return newRemote
end

local function canSetJoinNextMatch(player: Player): boolean
	if matchPhase ~= PHASE_LOBBY and matchPhase ~= PHASE_IN_MATCH then
		return false
	end
	if player:GetAttribute(ATTR_MATCH_PARTICIPANT) == true then
		return false
	end
	if player.Team ~= nil then
		return false
	end
	if not player.Neutral then
		return false
	end
	if matchPhase == PHASE_IN_MATCH and player:GetAttribute("IsOut") == true then
		return false
	end
	return true
end

-- Default opt-in only on first join (attribute still nil). Never override explicit false.
local function applyDefaultJoinNextMatchOnPlayerAdded(player: Player)
	if not canSetJoinNextMatch(player) then
		return
	end
	if player:GetAttribute(ATTR_JOIN_NEXT_MATCH) ~= nil then
		return
	end
	player:SetAttribute(ATTR_JOIN_NEXT_MATCH, true)
end

local function applyLobbyCountdownAfterOptInChange()
	if matchPhase ~= PHASE_LOBBY then
		return
	end
	if countOptedInPlayers() < 2 then
		if not countdownPaused or lobbyCountdownEndsAt ~= nil then
			if countPlayers() < 2 then
				warn("[LobbyService] Only 1 player — lobby countdown paused and reset.")
			else
				warn("[LobbyService] Fewer than 2 opted in for next match — countdown paused and reset.")
			end
		end
		resetLobbyCountdownFull()
		return
	end
	ensureLobbyCountdownRunning()
end

local function afterLobbyPopulationChange()
	publishMatchStatus()
	applyLobbyCountdownAfterOptInChange()
end

local function setPlayerJoinNextMatch(player: Player, wantsIn: boolean)
	if not canSetJoinNextMatch(player) then
		warn(`[LobbyService] Ignored JoinNextMatch for {player.Name} — not a qualifying neutral spectator.`)
		return
	end
	player:SetAttribute(ATTR_JOIN_NEXT_MATCH, if wantsIn then true else false)
	warn(
		`[LobbyService] {player.Name} opt-{(if wantsIn then "IN" else "OUT")} for next match ({matchPhase}; no team change this phase).`
	)
	publishMatchStatus()
	if matchPhase == PHASE_LOBBY then
		applyLobbyCountdownAfterOptInChange()
	end
end

local function wireJoinNextMatchRemote()
	local remote = getSetJoinNextMatchRemote()
	remote.OnServerEvent:Connect(function(player: Player, wantsIn: unknown)
		if typeof(wantsIn) ~= "boolean" then
			return
		end
		setPlayerJoinNextMatch(player, wantsIn)
	end)
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
	if countOptedInPlayers() < 2 then
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
	clearAllMatchParticipants()
	initMatchScores()
	resetLobbyCountdownFull()
	publishMatchStatus()
	warn(`[LobbyService] Lobby phase ({reason}). First to {Config.MATCH_POINTS_TO_WIN} round wins takes the match.`)
	task.defer(function()
		respawnAllAtLobby()
		afterLobbyPopulationChange()
	end)
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
	if countOptedInPlayers() < 2 then
		resetLobbyCountdownFull()
		warn("[LobbyService] Match start blocked — need 2+ players opted in for next match.")
		return
	end
	matchPhase = PHASE_IN_MATCH
	lobbyCountdownEndsAt = nil
	countdownPaused = true
	publishMatchStatus()
	warn("[LobbyService] Match started — teams to arena spawns!")

	if not invokeBridge("AssignMatchTeams") then
		warn("[LobbyService] Match start aborted — could not assign teams (is TeamAutoBalance running?).")
		matchPhase = PHASE_LOBBY
		publishMatchStatus()
		task.defer(ensureLobbyCountdownRunning)
		return
	end

	local playerList = Players:GetPlayers()
	table.sort(playerList, function(a, b)
		return a.UserId < b.UserId
	end)

	for _, player in playerList do
		if player.Team then
			player:SetAttribute(ATTR_MATCH_PARTICIPANT, true)
			player:SetAttribute("IsOut", false)
			spawnPlayerAtTeamArena(player)
		else
			player:SetAttribute(ATTR_MATCH_PARTICIPANT, false)
			if playerJoinNextMatchOptedIn(player) then
				warn(`[LobbyService] {player.Name} opted in but has no team — staying lobby spectator.`)
			end
		end
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

	local optedIn = countOptedInPlayers()
	if optedIn < 2 then
		if not countdownPaused or lobbyCountdownEndsAt ~= nil then
			if countPlayers() < 2 then
				warn("[LobbyService] Only 1 player — lobby countdown paused and reset.")
			else
				warn("[LobbyService] Fewer than 2 opted in for next match — countdown paused and reset.")
			end
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

	local respawnArenaFn = bridge:FindFirstChild("RespawnAllAtTeamArena")
	if not respawnArenaFn then
		respawnArenaFn = Instance.new("BindableFunction")
		respawnArenaFn.Name = "RespawnAllAtTeamArena"
		respawnArenaFn.Parent = bridge
	end

	(respawnArenaFn :: BindableFunction).OnInvoke = function(): boolean
		if matchPhase ~= PHASE_IN_MATCH then
			return false
		end
		respawnAllPlayersAtTeamArena()
		return true
	end

	local sidelineFn = bridge:FindFirstChild("SidelineOutCharacterAtLobby")
	if not sidelineFn then
		sidelineFn = Instance.new("BindableFunction")
		sidelineFn.Name = "SidelineOutCharacterAtLobby"
		sidelineFn.Parent = bridge
	end

	(sidelineFn :: BindableFunction).OnInvoke = function(player: Instance): boolean
		if player and player:IsA("Player") then
			sidelineOutCharacterAtLobby(player)
		end
		return true
	end
end

local function onPlayerAdded(player: Player)
	if matchPhase == PHASE_LOBBY then
		task.defer(function()
			if player.Parent and matchPhase == PHASE_LOBBY then
				respawnPlayerAtLobby(player)
				applyDefaultJoinNextMatchOnPlayerAdded(player)
				afterLobbyPopulationChange()
			end
		end)
	elseif matchPhase == PHASE_IN_MATCH then
		player:SetAttribute(ATTR_MATCH_PARTICIPANT, false)
		task.defer(function()
			if
				player.Parent
				and matchPhase == PHASE_IN_MATCH
				and player:GetAttribute(ATTR_MATCH_PARTICIPANT) == false
			then
				respawnSpectatorAtLobby(player)
				applyDefaultJoinNextMatchOnPlayerAdded(player)
				publishMatchStatus()
			end
		end)
	end
end

local function onPlayerRemoving(player: Player)
	if matchPhase == PHASE_LOBBY then
		task.defer(function()
			local remaining = countOptedInPlayers()
			if remaining < 2 then
				resetLobbyCountdownFull()
			elseif playerJoinNextMatchOptedIn(player) then
				afterLobbyPopulationChange()
			end
		end)
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
wireJoinNextMatchRemote()
publishMatchStatus()
enterLobbyPhase("server start")

task.spawn(function()
	while true do
		onLobbyTick()
		task.wait(0.25)
	end
end)
