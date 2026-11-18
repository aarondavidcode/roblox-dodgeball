-- Studio setup: DodgeballSinglePlayerTest.md
-- Chat commands for solo arena testing when DodgeballDebugConfig.SINGLE_PLAYER_TESTING is true.

--!strict

local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

local DebugConfig = require(ServerScriptService:WaitForChild("DodgeballDebugConfig"))
local MatchNpc = require(ServerScriptService:WaitForChild("DodgeballMatchNpc"))

local DEFAULT_NPC_COUNT = 3
local MAX_NPC_COUNT = 15
local PREFIX = "[DodgeballSinglePlayerTest]"

local function singlePlayerTestingEnabled(): boolean
	return DebugConfig.SINGLE_PLAYER_TESTING == true
end

local function parseNpcCount(message: string): number?
	local trimmed = string.gsub(message, "^%s+", "")
	trimmed = string.gsub(trimmed, "%s+$", "")
	local lower = string.lower(trimmed)

	local countStr = string.match(lower, "^/testmatch%s+(%d+)$")
	if countStr then
		return tonumber(countStr)
	end
	if lower == "/testmatch" then
		return DEFAULT_NPC_COUNT
	end

	countStr = string.match(lower, "^/starttest%s+(%d+)$")
	if countStr then
		return tonumber(countStr)
	end
	if lower == "/starttest" then
		return DEFAULT_NPC_COUNT
	end

	if lower == "/testhelp" or lower == "/testmatch help" then
		return -1
	end
	return nil
end

local function startTestMatch(player: Player, npcCount: number): boolean
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if not bridge then
		warn(`{PREFIX} DodgeballRoundBridge missing — is LobbyService loaded?`)
		return false
	end
	local bindable = bridge:FindFirstChild("StartSinglePlayerTestMatch")
	if not bindable or not bindable:IsA("BindableFunction") then
		warn(`{PREFIX} StartSinglePlayerTestMatch missing — update LobbyService.`)
		return false
	end
	local ok, result = pcall(function()
		return (bindable :: BindableFunction):Invoke(player, npcCount)
	end)
	if not ok then
		warn(`{PREFIX} StartSinglePlayerTestMatch failed: {result}`)
		return false
	end
	return result == true
end

local function sendHelp(player: Player)
	warn(
		`{PREFIX} Commands (studio debug): /testmatch [npcCount], /starttest [npcCount] — default {DEFAULT_NPC_COUNT}, max {MAX_NPC_COUNT}. Set SINGLE_PLAYER_TESTING in DodgeballDebugConfig.`
	)
	player:SetAttribute("LastTestMatchHint", workspace:GetServerTimeNow())
end

local function onPlayerChatted(player: Player, message: string)
	local parsed = parseNpcCount(message)
	if parsed == nil then
		return
	end
	if parsed == -1 then
		sendHelp(player)
		return
	end
	if not singlePlayerTestingEnabled() then
		warn(`{PREFIX} {player.Name}: single-player testing is off (DodgeballDebugConfig.SINGLE_PLAYER_TESTING).`)
		return
	end

	local npcCount = parsed
	if npcCount < 1 or npcCount > MAX_NPC_COUNT then
		warn(`{PREFIX} {player.Name}: npc count must be 1–{MAX_NPC_COUNT}.`)
		return
	end

	if not startTestMatch(player, npcCount) then
		warn(`{PREFIX} {player.Name}: could not start test match (lobby only, one match at a time).`)
	else
		warn(`{PREFIX} {player.Name} started test match with {npcCount} NPC(s).`)
		MatchNpc.beginRandomWalk()
	end
end

local function hookPlayer(player: Player)
	player.Chatted:Connect(function(message)
		onPlayerChatted(player, message)
	end)
end

Players.PlayerAdded:Connect(hookPlayer)
for _, player in Players:GetPlayers() do
	hookPlayer(player)
end

if singlePlayerTestingEnabled() then
	warn(`{PREFIX} Loaded — chat /testmatch [count] or /starttest [count] in lobby.`)
else
	warn(`{PREFIX} Loaded — enable SINGLE_PLAYER_TESTING in DodgeballDebugConfig for commands.`)
end