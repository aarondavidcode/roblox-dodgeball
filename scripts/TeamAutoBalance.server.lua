-- Paste this as a Script named TeamAutoBalance under ServerScriptService.
-- Teams in your place must be named exactly Red and Blue (see TEAM_NAMES below).

--!strict

local Players = game:GetService("Players")
local Teams = game:GetService("Teams")

-- Change these only if you rename teams in Studio (names must match Explorer).
local TEAM_NAMES = { "Red", "Blue" }

-- Find a team by exact name, or warn in Output if something is misspelled.
local function getTeam(name: string): Team?
	local team = Teams:FindFirstChild(name)
	if team and team:IsA("Team") then
		return team
	end
	warn(`[TeamAutoBalance] Missing Team named {name}. Check Explorer → Teams.`)
	return nil
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
local function assignBalancedTeam(player: Player)
	local redTeam = getTeam(TEAM_NAMES[1])
	local blueTeam = getTeam(TEAM_NAMES[2])
	if not redTeam or not blueTeam then
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

	player.Team = chosenTeam
	player.Neutral = false -- Must be false so team spawns and colors work.

	-- Loads (or reloads) the character so Roblox uses the right SpawnLocation.
	player:LoadCharacter()
end

-- Run when someone new joins the experience (including Studio test players).
local function onPlayerAdded(player: Player)
	assignBalancedTeam(player)
end

Players.PlayerAdded:Connect(onPlayerAdded)

-- Studio: if you press Play after the script loads, catch players who joined first.
for _, player in Players:GetPlayers() do
	task.defer(function()
		assignBalancedTeam(player)
	end)
end

-- PlayerRemoving: no extra logic needed; next join re-counts both teams.