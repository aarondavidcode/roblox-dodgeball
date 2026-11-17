-- Studio setup: ../../DodgeballBallVisualEffectsDebug/DodgeballBallVisualEffectsDebug.md
-- Same source as scripts/DodgeballBallVisualEffectsDebug — paste here under ballVisualEffects.

--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local PREFIX = "[DodgeballBallVisualEffectsDebug]"

local DodgeballBallVisualEffectsDebug = {}

local function readServerConfigFlag(): boolean
	local configModule = ServerScriptService:FindFirstChild("DodgeballDebugConfig")
	if not configModule or not configModule:IsA("ModuleScript") then
		return false
	end
	local ok, config = pcall(require, configModule)
	if not ok or typeof(config) ~= "table" then
		return false
	end
	return config.DEBUG_BALL_VISUAL_EFFECTS == true
end

local function readRemotesFlag(): boolean
	local folder = ReplicatedStorage:FindFirstChild("DodgeballRemotes")
	if folder and folder:IsA("Folder") and folder:GetAttribute("DEBUG_BALL_VISUAL_EFFECTS") == true then
		return true
	end
	return false
end

function DodgeballBallVisualEffectsDebug.isEnabled(): boolean
	return readServerConfigFlag() or readRemotesFlag()
end

function DodgeballBallVisualEffectsDebug.log(message: string)
	if not DodgeballBallVisualEffectsDebug.isEnabled() then
		return
	end
	print(`{PREFIX} {message}`)
end

function DodgeballBallVisualEffectsDebug.warn(message: string)
	if not DodgeballBallVisualEffectsDebug.isEnabled() then
		return
	end
	warn(`{PREFIX} {message}`)
end

function DodgeballBallVisualEffectsDebug.formatColor3(color: Color3): string
	return `rgb({math.floor(color.R * 255)},{math.floor(color.G * 255)},{math.floor(color.B * 255)})`
end

function DodgeballBallVisualEffectsDebug.snapshotRemotesAttrs(folder: Folder): string
	local names = {
		"HIT_MIN_SPEED",
		"SPEED_GLOW_HYSTERESIS_FRACTION",
		"SPEED_GLOW_SHELL_DIAMETER_SCALE",
		"DEFAULT_BALL_VISUAL_EFFECT",
		"BALL_VISUAL_EFFECT_SPECTATOR_COLOR",
		"DODGEBALL_TAG",
		"LOBBY_PRACTICE_BALL_TAG",
		"BALL_PHYSICS_TAG",
		"DEBUG_BALL_VISUAL_EFFECTS",
	}
	local parts = {}
	for _, name in names do
		local value = folder:GetAttribute(name)
		local text: string
		if value == nil then
			text = "nil"
		elseif typeof(value) == "Color3" then
			text = DodgeballBallVisualEffectsDebug.formatColor3(value)
		else
			text = tostring(value)
		end
		if value == nil then
			DodgeballBallVisualEffectsDebug.warn(`remotes missing attr {name}`)
		end
		table.insert(parts, `{name}={text}`)
	end
	return table.concat(parts, " ")
end

return DodgeballBallVisualEffectsDebug
