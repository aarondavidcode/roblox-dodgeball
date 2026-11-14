-- Paste this as a Script named TeamAutoBalance under ServerScriptService.
-- Teams in your place must be named exactly Red and Blue (see TEAM_NAMES below).

--!strict

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")
local StarterPlayer = game:GetService("StarterPlayer")

-- Change these only if you rename teams in Studio (names must match Explorer).
local TEAM_NAMES = { "Red", "Blue" }

-- How long we wait for Teams to show up (Studio can load folders in any order).
local TEAM_WAIT_SECONDS = 10

local redTeam: Team?
local blueTeam: Team?

-- One safety-net respawn per player (stops endless LoadCharacter loops).
local usedSpawnSafetyNet: { [Player]: boolean } = {}

-- Wait for both teams by exact name. Warn clearly if a name is wrong or missing.
local function waitForTeams(): boolean
	local red = Teams:WaitForChild(TEAM_NAMES[1], TEAM_WAIT_SECONDS)
	if not red or not red:IsA("Team") then
		warn(`[TeamAutoBalance] Missing Team named "{TEAM_NAMES[1]}" after {TEAM_WAIT_SECONDS}s. Check Explorer → Teams (spelling and capitals).`)
		return false
	end

	local blue = Teams:WaitForChild(TEAM_NAMES[2], TEAM_WAIT_SECONDS)
	if not blue or not blue:IsA("Team") then
		warn(`[TeamAutoBalance] Missing Team named "{TEAM_NAMES[2]}" after {TEAM_WAIT_SECONDS}s. Check Explorer → Teams (spelling and capitals).`)
		return false
	end

	redTeam = red
	blueTeam = blue
	return true
end

-- How many players are currently on this team?
local function countPlayersOnTeam(team: Team): number
	local total = 0
	for _, player in Players:GetPlayers() do
		if player.Team == team then
			total += 1
		end
	end
	return total
end

-- Put the player on Red or Blue, whichever has fewer players right now.
local function assignBalancedTeam(player: Player, needsRespawn: boolean)
	if not redTeam or not blueTeam then
		warn("[TeamAutoBalance] Red or Blue team is not ready yet. Check Teams in Explorer.")
		return
	end

	local redCount = countPlayersOnTeam(redTeam)
	local blueCount = countPlayersOnTeam(blueTeam)

	-- Fewer players wins; if tied, Red gets the next player (simple and predictable).
	local chosenTeam: Team
	if redCount <= blueCount then
		chosenTeam = redTeam
	else
		chosenTeam = blueTeam
	end

	-- Roblox works best when Neutral is off *before* you set Team (team spawn + player list).
	player.Neutral = false
	player.Team = chosenTeam

	-- If CharacterAutoLoads is on, Roblox spawns for us once team + Neutral are set.
	-- We only call LoadCharacter when we must fix a spawn or when auto-load is off.
	local shouldLoad = needsRespawn
	if not player.Character and not StarterPlayer.CharacterAutoLoads then
		shouldLoad = true
	end
	if shouldLoad then
		player:LoadCharacter()
	end
end

-- If CharacterAutoLoads spawns you before team assignment, fix team once and respawn.
local function trySpawnSafetyNet(player: Player)
	if player.Team ~= nil and not player.Neutral then
		return
	end
	if usedSpawnSafetyNet[player] then
		return
	end
	usedSpawnSafetyNet[player] = true
	assignBalancedTeam(player, true)
end

local function hookCharacterAdded(player: Player)
	player.CharacterAdded:Connect(function()
		trySpawnSafetyNet(player)
	end)
end

-- Run when someone new joins the experience (including Studio test players).
local function onPlayerAdded(player: Player)
	hookCharacterAdded(player)

	-- Set team right away. Respawn only if a character already appeared (often Neutral first).
	assignBalancedTeam(player, player.Character ~= nil)
end

Players.PlayerRemoving:Connect(function(player)
	usedSpawnSafetyNet[player] = nil
end)

if not waitForTeams() then
	warn("[TeamAutoBalance] Stopping — create teams named Red and Blue, then play again.")
	return
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Studio: if you press Play after the script loads, catch players who joined first.
for _, player in Players:GetPlayers() do
	task.defer(function()
		onPlayerAdded(player)
	end)
end

-- PlayerRemoving: no extra logic needed; next join re-counts both teams.