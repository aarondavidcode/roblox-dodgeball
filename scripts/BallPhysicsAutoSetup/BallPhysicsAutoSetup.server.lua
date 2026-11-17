-- Studio setup: BallPhysicsAutoSetup.md
-- Tracks CollectionService-tagged dodgeball parts through BallPhysics (server handlers).
-- Requires ReplicatedStorage/BallPhysics tree and DodgeballConfig applied tuning.

--!strict

local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local DodgeballConfig = require(ServerScriptService:WaitForChild("DodgeballConfig"))
local BallPhysicsDebug = require(ServerScriptService:WaitForChild("DodgeballBallPhysicsDebug"))

local BALL_PHYSICS_LAYOUT_HINT =
	"ReplicatedStorage/BallPhysics must be a ModuleScript (paste init.luau) with Config child — not a Folder"

local function getBallPhysicsEntry(): ModuleScript?
	local inst = ReplicatedStorage:FindFirstChild("BallPhysics")
	if not inst then
		BallPhysicsDebug.warn(`BallPhysics missing under ReplicatedStorage — {BALL_PHYSICS_LAYOUT_HINT}`)
		inst = ReplicatedStorage:WaitForChild("BallPhysics", 120)
	end
	if inst:IsA("Folder") then
		BallPhysicsDebug.warn(`BallPhysics is a Folder (cannot require) — {BALL_PHYSICS_LAYOUT_HINT}`)
		return nil
	end
	if not inst:IsA("ModuleScript") then
		BallPhysicsDebug.warn(`BallPhysics is a {inst.ClassName}, expected ModuleScript — {BALL_PHYSICS_LAYOUT_HINT}`)
		return nil
	end
	if not inst:FindFirstChild("Config") then
		BallPhysicsDebug.warn(`BallPhysics ModuleScript has no Config child — {BALL_PHYSICS_LAYOUT_HINT}`)
		return nil
	end
	return inst
end

local ballPhysicsEntry = getBallPhysicsEntry()
if not ballPhysicsEntry then
	BallPhysicsDebug.warn("BallPhysicsAutoSetup stopped — fix Explorer layout (see ball-physics/README.md)")
	return
end

local okLoad, BallPhysics = pcall(require, ballPhysicsEntry)
if not okLoad or typeof(BallPhysics) ~= "table" or typeof(BallPhysics.new) ~= "function" then
	BallPhysicsDebug.warn(`BallPhysics require failed err={tostring(BallPhysics)} — {BALL_PHYSICS_LAYOUT_HINT}`)
	return
end
BallPhysicsDebug.log("BallPhysics library loaded (ModuleScript root)")

local PhysicsConfig = require(ballPhysicsEntry:WaitForChild("Config"))

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

if BallPhysicsDebug.isEnabled() then
	BallPhysicsDebug.log("AutoSetup running")
	BallPhysicsDebug.log(
		`configEffects magnus={PhysicsConfig.magnus.enabled} knuckle={PhysicsConfig.knuckleball.enabled} antiGravity={PhysicsConfig.antiGravity.enabled} angularDamping={PhysicsConfig.angularDamping.enabled} ballTag={PhysicsConfig.ballTag}`
	)
	local starterPlayer = game:GetService("StarterPlayer")
	local starterScripts = starterPlayer:FindFirstChild("StarterPlayerScripts")
	if not starterScripts or not starterScripts:FindFirstChild("BallPhysicsClient") then
		BallPhysicsDebug.warn("BallPhysicsClient LocalScript missing under StarterPlayerScripts")
	end
	local autoSetupSelf = ServerScriptService:FindFirstChild("BallPhysicsAutoSetup")
	if not autoSetupSelf or not autoSetupSelf:IsA("Script") then
		BallPhysicsDebug.warn("BallPhysicsAutoSetup Script missing under ServerScriptService")
	end
end

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

	local tagName = physicsTag()
	local hasTag = CollectionService:HasTag(ball, tagName)
	if BallPhysicsDebug.isEnabled() and not hasTag then
		BallPhysicsDebug.warn(`track ball={ball:GetFullName()} missing tag={tagName} — handler may never run`)
	end

	local success, result = pcall(BallPhysics.new, ball)
	if success then
		handlers[ball] = result :: ServerHandle
		BallPhysicsDebug.log(`handler created ball={ball.Name} hasTag={hasTag} BallPhysics.new=ok`)
	else
		warn("[BallPhysicsAutoSetup] failed to track", ball, "-", result)
		BallPhysicsDebug.warn(`handler failed ball={ball.Name} err={tostring(result)}`)
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
		BallPhysicsDebug.log(`handler destroyed ball={ball.Name}`)
	end
end

local tag = physicsTag()

for _, instance in CollectionService:GetTagged(tag) do
	task.spawn(track, instance)
end

CollectionService:GetInstanceAddedSignal(tag):Connect(track)
CollectionService:GetInstanceRemovedSignal(tag):Connect(untrack)
