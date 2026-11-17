-- Studio setup: DodgeballThrowerCollision.md
-- ModuleScript DodgeballThrowerCollision under ServerScriptService.
-- Short throw-release grace: thrower character parts do not collide with dodgeballs.

--!strict

local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local GROUP_BALL = "DodgeballBall"
local GROUP_THROWER = "DodgeballThrower"

local graceToken: { [Player]: number } = {}
local savedGroups: { [Player]: { [BasePart]: string } } = {}

local function registerCollisionGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_BALL)
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup(GROUP_THROWER)
	end)
	pcall(function()
		PhysicsService:CollisionGroupSetCollidable(GROUP_BALL, GROUP_THROWER, false)
	end)
end

registerCollisionGroups()

local function graceDurationSeconds(): number
	local seconds = Config.THROWER_BALL_NOCOLLIDE_SECONDS
	if typeof(seconds) ~= "number" or seconds <= 0 then
		return 0
	end
	return seconds
end

local function revertThrowerCollision(player: Player)
	local saved = savedGroups[player]
	if not saved then
		return
	end
	for part, group in saved do
		if part.Parent then
			part.CollisionGroup = group
		end
	end
	savedGroups[player] = nil
end

local DodgeballThrowerCollision = {}

function DodgeballThrowerCollision.assignBallCollisionGroup(part: BasePart)
	part.CollisionGroup = GROUP_BALL
end

-- Call when the ball leaves the thrower's hand (throw impulse or hold roll).
function DodgeballThrowerCollision.beginThrowerGrace(player: Player, ball: BasePart?)
	local duration = graceDurationSeconds()
	if duration <= 0 then
		return
	end

	revertThrowerCollision(player)

	if ball then
		DodgeballThrowerCollision.assignBallCollisionGroup(ball)
	end

	local character = player.Character
	if not character then
		return
	end

	local saved: { [BasePart]: string } = {}
	for _, desc in character:GetDescendants() do
		if desc:IsA("BasePart") then
			saved[desc] = desc.CollisionGroup
			desc.CollisionGroup = GROUP_THROWER
		end
	end
	savedGroups[player] = saved

	graceToken[player] = (graceToken[player] or 0) + 1
	local token = graceToken[player]
	task.delay(duration, function()
		if player.Parent == nil or graceToken[player] ~= token then
			return
		end
		revertThrowerCollision(player)
	end)
end

Players.PlayerRemoving:Connect(function(player)
	graceToken[player] = nil
	revertThrowerCollision(player)
end)

return DodgeballThrowerCollision
