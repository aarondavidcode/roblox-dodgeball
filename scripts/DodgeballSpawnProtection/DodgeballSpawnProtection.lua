-- Studio setup: DodgeballSpawnProtection.md
-- Disables Roblox default SpawnLocation respawn immunity (ForceField) for dodgeball.

--!strict

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local installed = false

local function disableSpawnLocationProtection(spawn: SpawnLocation)
	if spawn.Duration ~= 0 then
		spawn.Duration = 0
	end
end

local function disableAllSpawnLocationProtection()
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") then
			disableSpawnLocationProtection(descendant)
		end
	end
end

local function stripForceFieldsFromCharacter(character: Model)
	for _, descendant in character:GetDescendants() do
		if descendant:IsA("ForceField") then
			descendant:Destroy()
		end
	end
end

local function onCharacterAdded(character: Model)
	stripForceFieldsFromCharacter(character)
	character.ChildAdded:Connect(function(child)
		if child:IsA("ForceField") then
			child:Destroy()
		end
	end)
end

local function hookPlayer(player: Player)
	player.CharacterAdded:Connect(onCharacterAdded)
	if player.Character then
		onCharacterAdded(player.Character)
	end
end

local function install()
	if installed then
		return
	end
	installed = true

	disableAllSpawnLocationProtection()
	Workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("SpawnLocation") then
			disableSpawnLocationProtection(descendant)
		end
	end)

	for _, player in Players:GetPlayers() do
		hookPlayer(player)
	end
	Players.PlayerAdded:Connect(hookPlayer)
end

install()

local DodgeballSpawnProtection = {}

function DodgeballSpawnProtection.stripCharacter(character: Model)
	stripForceFieldsFromCharacter(character)
end

return DodgeballSpawnProtection