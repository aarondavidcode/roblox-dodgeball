-- Paste as Script named RoundService under ServerScriptService (with TeamAutoBalance + DodgeballService + LobbyService).
-- Ends a round when one team is all OUT; optional countdown; clears outs, respawns players and balls.
-- Rounds only run during match phase (LobbyService sets MatchPhase on ReplicatedStorage/RoundStatus).

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local ROUND_STATE_LOBBY_IDLE = "LobbyIdle"
local ROUND_STATE_PLAYING = "Playing"
local ROUND_STATE_INTERMISSION = "Intermission"
local ROUND_STATE_RESETTING = "Resetting"

local MATCH_PHASE_IN_MATCH = "InMatch"

local roundNumber = 1
local phase: string = ROUND_STATE_LOBBY_IDLE
local resetScheduled = false

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

local function getMatchPhase(): string
	local matchPhase = roundStatus:GetAttribute("MatchPhase")
	if typeof(matchPhase) == "string" then
		return matchPhase
	end
	return "Lobby"
end

local function matchIsLive(): boolean
	return getMatchPhase() == MATCH_PHASE_IN_MATCH
end

local function getTeam(name: string): Team?
	local team = Teams:FindFirstChild(name)
	if team and team:IsA("Team") then
		return team
	end
	warn(`[RoundService] Missing Team "{name}". Check TeamAutoBalance teams in Explorer.`)
	return nil
end

local function publishRoundStatus(state: string, intermissionEndsAt: number?)
	roundStatus:SetAttribute("RoundState", state)
	roundStatus:SetAttribute("RoundNumber", roundNumber)
	if intermissionEndsAt then
		roundStatus:SetAttribute("IntermissionEndsAt", intermissionEndsAt)
	else
		roundStatus:SetAttribute("IntermissionEndsAt", nil)
	end
end

local function waitForBridge(maxSeconds: number): Folder?
	local deadline = os.clock() + maxSeconds
	while os.clock() < deadline do
		local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
		if bridge and bridge:IsA("Folder") then
			return bridge
		end
		task.wait(0.1)
	end
	warn("[RoundService] DodgeballRoundBridge not found — ball reset may not run. Is DodgeballService loaded?")
	return nil
end

local bridge = waitForBridge(15)

local function invokeBridge(functionName: string): boolean
	if not bridge then
		return false
	end
	local bindable = bridge:FindFirstChild(functionName)
	if bindable and bindable:IsA("BindableFunction") then
		local ok, result = pcall(function()
			return (bindable :: BindableFunction):Invoke()
		end)
		if not ok then
			warn(`[RoundService] {functionName} failed: {result}`)
			return false
		end
		return result == true
	end
	warn(`[RoundService] Missing BindableFunction {functionName} in DodgeballRoundBridge.`)
	return false
end

local function shouldContinueMatchAfterRound(winningTeam: Team?): boolean
	if not winningTeam or not bridge then
		return true
	end
	local notify = bridge:FindFirstChild("NotifyRoundWin")
	if notify and notify:IsA("BindableFunction") then
		local ok, result = pcall(function()
			return (notify :: BindableFunction):Invoke(winningTeam)
		end)
		if ok and result == false then
			return false
		end
	end
	return true
end

local function isPlayerOut(player: Player): boolean
	return player:GetAttribute("IsOut") == true
end

local function isTeamFullyOut(team: Team): boolean
	local hasMember = false
	for _, player in Players:GetPlayers() do
		if player.Team == team then
			hasMember = true
			if not isPlayerOut(player) then
				return false
			end
		end
	end
	return hasMember
end

local function anyPlayerStillIn(team: Team): boolean
	for _, player in Players:GetPlayers() do
		if player.Team == team and not isPlayerOut(player) then
			return true
		end
	end
	return false
end

local function everyoneInGameIsOut(): boolean
	local anyPlayer = false
	for _, player in Players:GetPlayers() do
		anyPlayer = true
		if not isPlayerOut(player) then
			return false
		end
	end
	return anyPlayer
end

local function describeWinningTeam(): Team?
	local teamAName = Config.TEAM_NAMES[1]
	local teamBName = Config.TEAM_NAMES[2]
	if typeof(teamAName) ~= "string" or typeof(teamBName) ~= "string" then
		return nil
	end
	local teamA = getTeam(teamAName)
	local teamB = getTeam(teamBName)
	if not teamA or not teamB then
		return nil
	end

	if isTeamFullyOut(teamA) and anyPlayerStillIn(teamB) then
		return teamB
	end
	if isTeamFullyOut(teamB) and anyPlayerStillIn(teamA) then
		return teamA
	end
	return nil
end

local function respawnAllPlayersAtArena()
	for _, player in Players:GetPlayers() do
		player.Neutral = false
		player.CharacterAutoLoads = true
		player:LoadCharacter()
	end
end

local function beginArenaRound(roundLabel: number)
	roundNumber = roundLabel
	phase = ROUND_STATE_PLAYING
	resetScheduled = false
	publishRoundStatus(ROUND_STATE_PLAYING, nil)
	warn(`[RoundService] Round {roundNumber} started — good luck!`)
end

local function runRoundReset(winningTeam: Team?, reason: string)
	if resetScheduled then
		return
	end
	if not matchIsLive() then
		return
	end
	resetScheduled = true
	phase = ROUND_STATE_RESETTING

	if winningTeam then
		warn(`[RoundService] Round {roundNumber} over — {winningTeam.Name} wins! ({reason})`)
	else
		warn(`[RoundService] Round {roundNumber} tie — everyone OUT. Resetting. ({reason})`)
	end

	local intermission = Config.ROUND_INTERMISSION_SECONDS
	if intermission > 0 then
		phase = ROUND_STATE_INTERMISSION
		local endsAt = workspace:GetServerTimeNow() + intermission
		publishRoundStatus(ROUND_STATE_INTERMISSION, endsAt)
		task.wait(intermission)
	end

	local continueMatch = shouldContinueMatchAfterRound(winningTeam)

	publishRoundStatus(ROUND_STATE_RESETTING, nil)

	invokeBridge("DropAllHeldBalls")
	invokeBridge("ClearAllOuts")
	invokeBridge("ResetBallsToSpawn")

	if continueMatch and matchIsLive() then
		respawnAllPlayersAtArena()
		beginArenaRound(roundNumber + 1)
		return
	end

	roundNumber = 1
	phase = ROUND_STATE_LOBBY_IDLE
	resetScheduled = false
	publishRoundStatus(ROUND_STATE_LOBBY_IDLE, nil)
	warn("[RoundService] Match ended or lobby phase — arena rounds paused.")
end

local function evaluateWinCondition()
	if not matchIsLive() or phase ~= ROUND_STATE_PLAYING or resetScheduled then
		return
	end

	local winner = describeWinningTeam()
	if winner then
		runRoundReset(winner, "one team all OUT")
		return
	end

	if everyoneInGameIsOut() then
		task.delay(Config.ROUND_TIE_RESET_DELAY_SECONDS, function()
			if matchIsLive() and phase == ROUND_STATE_PLAYING and not resetScheduled and everyoneInGameIsOut() then
				runRoundReset(nil, "tie — all OUT")
			end
		end)
	end
end

local function hookPlayer(player: Player)
	player:GetAttributeChangedSignal("IsOut"):Connect(function()
		if player:GetAttribute("IsOut") == true then
			task.defer(evaluateWinCondition)
		end
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

if bridge then
	local elim = bridge:FindFirstChild("PlayerEliminated")
	if elim and elim:IsA("BindableEvent") then
		elim.Event:Connect(function()
			task.defer(evaluateWinCondition)
		end)
	end

	local beginMatch = bridge:FindFirstChild("BeginMatchRound")
	if not beginMatch then
		beginMatch = Instance.new("BindableEvent")
		beginMatch.Name = "BeginMatchRound"
		beginMatch.Parent = bridge
	end
	(beginMatch :: BindableEvent).Event:Connect(function()
		beginArenaRound(1)
	end)
end

roundStatus:GetAttributeChangedSignal("MatchPhase"):Connect(function()
	if getMatchPhase() ~= MATCH_PHASE_IN_MATCH then
		phase = ROUND_STATE_LOBBY_IDLE
		resetScheduled = false
		publishRoundStatus(ROUND_STATE_LOBBY_IDLE, nil)
	end
end)

publishRoundStatus(ROUND_STATE_LOBBY_IDLE, nil)
warn("[RoundService] Waiting for lobby match start — rounds run only during InMatch.")