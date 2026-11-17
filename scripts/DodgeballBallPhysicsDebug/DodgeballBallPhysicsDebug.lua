-- Studio setup: DodgeballBallPhysicsDebug.md
-- Shared Output helpers for BallPhysics integration diagnostics (server + optional client).

--!strict

local PREFIX = "[DodgeballBallPhysicsDebug]"

local DodgeballBallPhysicsDebug = {}

local function readConfigFlag(): boolean
	local ServerScriptService = game:GetService("ServerScriptService")
	local configModule = ServerScriptService:FindFirstChild("DodgeballDebugConfig")
	if not configModule or not configModule:IsA("ModuleScript") then
		return false
	end
	local ok, config = pcall(require, configModule)
	if not ok or typeof(config) ~= "table" then
		return false
	end
	return config.DEBUG_BALL_PHYSICS == true
end

local function readRemotesFlag(): boolean
	local ReplicatedStorage = game:GetService("ReplicatedStorage")
	local folder = ReplicatedStorage:FindFirstChild("DodgeballRemotes")
	if folder and folder:IsA("Folder") and folder:GetAttribute("DEBUG_BALL_PHYSICS") == true then
		return true
	end
	return false
end

function DodgeballBallPhysicsDebug.isEnabled(): boolean
	return readConfigFlag() or readRemotesFlag()
end

function DodgeballBallPhysicsDebug.log(message: string)
	if not DodgeballBallPhysicsDebug.isEnabled() then
		return
	end
	print(`{PREFIX} {message}`)
end

function DodgeballBallPhysicsDebug.warn(message: string)
	if not DodgeballBallPhysicsDebug.isEnabled() then
		return
	end
	warn(`{PREFIX} {message}`)
end

function DodgeballBallPhysicsDebug.formatNetworkOwner(part: BasePart): string
	if not part:CanSetNetworkOwnership() then
		return "ownership-locked"
	end
	local owner = part:GetNetworkOwner()
	if owner then
		return `client:{owner.Name}`
	end
	return "server"
end

function DodgeballBallPhysicsDebug.logBallState(ball: BasePart, context: string)
	if not DodgeballBallPhysicsDebug.isEnabled() then
		return
	end
	local lin = ball.AssemblyLinearVelocity.Magnitude
	local ang = ball.AssemblyAngularVelocity.Magnitude
	DodgeballBallPhysicsDebug.log(
		`{context} ball={ball:GetFullName()} owner={DodgeballBallPhysicsDebug.formatNetworkOwner(ball)} massless={ball.Massless} lin={string.format(
			"%.2f",
			lin
		)} ang={string.format("%.2f", ang)}`
	)
end

return DodgeballBallPhysicsDebug
