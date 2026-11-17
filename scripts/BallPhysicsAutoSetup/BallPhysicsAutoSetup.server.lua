-- Studio setup: BallPhysicsAutoSetup.md
-- Tracks CollectionService-tagged dodgeball parts through BallPhysics (server handlers).
-- Requires ReplicatedStorage/BallPhysics tree and DodgeballConfig applied tuning.

--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DodgeballConfig = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local ballPhysicsModule = ReplicatedStorage:WaitForChild("BallPhysics")
local BallPhysics = require(ballPhysicsModule)
local PhysicsConfig = require(ballPhysicsModule:WaitForChild("Config"))

type ServerHandle = { Destroy: (self: ServerHandle) -> () }

local function physicsTag(): string
	local tag = DodgeballConfig.BALL_PHYSICS_TAG
	if typeof(tag) ~= "string" or tag == "" then
		return "PhysicsBall"
	end
	return tag
end

local function applyDodgeballTuning()
	PhysicsConfig.ballTag = physicsTag()

	local magnusOn = DodgeballConfig.BALL_PHYSICS_MAGNUS_ENABLED
	if typeof(magnusOn) == "boolean" then
		PhysicsConfig.magnus.enabled = magnusOn
	end
	local magnusStrength = DodgeballConfig.BALL_PHYSICS_MAGNUS_STRENGTH
	if typeof(magnusStrength) == "number" then
		PhysicsConfig.magnus.strength = magnusStrength
	end
	local magnusDensity = DodgeballConfig.BALL_PHYSICS_MAGNUS_DEFAULT_DENSITY
	if typeof(magnusDensity) == "number" then
		PhysicsConfig.magnus.defaultDensity = magnusDensity
	end

	local knuckleOn = DodgeballConfig.BALL_PHYSICS_KNUCKLE_ENABLED
	if typeof(knuckleOn) == "boolean" then
		PhysicsConfig.knuckleball.enabled = knuckleOn
	end
	local knuckleStrength = DodgeballConfig.BALL_PHYSICS_KNUCKLE_STRENGTH
	if typeof(knuckleStrength) == "number" then
		PhysicsConfig.knuckleball.strength = knuckleStrength
	end
	local knuckleTarget = DodgeballConfig.BALL_PHYSICS_KNUCKLE_TARGET_SPEED
	if typeof(knuckleTarget) == "number" then
		PhysicsConfig.knuckleball.targetSpeed = knuckleTarget
	end

	local dampOn = DodgeballConfig.BALL_PHYSICS_ANGULAR_DAMPING_ENABLED
	if typeof(dampOn) == "boolean" then
		PhysicsConfig.angularDamping.enabled = dampOn
	end
	local airRate = DodgeballConfig.BALL_PHYSICS_ANGULAR_DAMPING_AIR_RATE
	if typeof(airRate) == "number" then
		PhysicsConfig.angularDamping.airRate = airRate
	end
	local groundRate = DodgeballConfig.BALL_PHYSICS_ANGULAR_DAMPING_GROUND_RATE
	if typeof(groundRate) == "number" then
		PhysicsConfig.angularDamping.groundRate = groundRate
	end

	local antiOn = DodgeballConfig.BALL_PHYSICS_ANTIGRAVITY_ENABLED
	if typeof(antiOn) == "boolean" then
		PhysicsConfig.antiGravity.enabled = antiOn
	end
	local antiFrac = DodgeballConfig.BALL_PHYSICS_ANTIGRAVITY_FRACTION
	if typeof(antiFrac) == "number" then
		PhysicsConfig.antiGravity.fraction = antiFrac
	end

	local debugOn = DodgeballConfig.BALL_PHYSICS_DEBUG_ENABLED
	if typeof(debugOn) == "boolean" then
		PhysicsConfig.debug.enabled = debugOn
	end
end

applyDodgeballTuning()

local handlers: { [BasePart]: ServerHandle } = {}

local function track(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local ball = instance :: BasePart
	if handlers[ball] then
		return
	end
	if ball.Shape ~= Enum.PartType.Ball then
		return
	end

	local success, result = pcall(BallPhysics.new, ball)
	if success then
		handlers[ball] = result :: ServerHandle
	else
		warn("[BallPhysicsAutoSetup] failed to track", ball, "-", result)
	end
end

local function untrack(instance: Instance)
	if not instance:IsA("BasePart") then
		return
	end
	local ball = instance :: BasePart
	local handler = handlers[ball]
	if handler then
		handler:Destroy()
		handlers[ball] = nil
	end
end

local tag = physicsTag()

for _, instance in CollectionService:GetTagged(tag) do
	task.spawn(track, instance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(track)
CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack)
