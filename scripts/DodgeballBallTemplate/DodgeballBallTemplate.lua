-- Studio setup: DodgeballBallTemplate.md
-- ModuleScript DodgeballBallTemplate under ServerScriptService.
-- Applies shared BALL_* appearance from DodgeballConfig to match + lobby practice Parts.

--!strict

local CollectionService = game:GetService("CollectionService")
local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

local DodgeballBallTemplate = {}

local function ballDiameter(): number
	local d = Config.BALL_DIAMETER
	if typeof(d) ~= "number" or d <= 0 then
		return 2.5
	end
	return d
end

local function physicsTag(): string
	local tag = Config.BALL_PHYSICS_TAG
	if typeof(tag) ~= "string" or tag == "" then
		return "PhysicsBall"
	end
	return tag
end

local function ensurePhysicsTrackingTag(part: BasePart)
	local tag = physicsTag()
	if not CollectionService:HasTag(part, tag) then
		CollectionService:AddTag(part, tag)
	end
end

local function applyPhysicalProperties(part: BasePart)
	local density = Config.BALL_PHYSICAL_DENSITY
	local friction = Config.BALL_PHYSICAL_FRICTION
	local elasticity = Config.BALL_PHYSICAL_ELASTICITY
	if typeof(density) ~= "number" or typeof(friction) ~= "number" or typeof(elasticity) ~= "number" then
		return
	end
	part.CustomPhysicalProperties = PhysicalProperties.new(density, friction, elasticity)
end

-- Size, color, material, and optional custom density/friction/elasticity (does not change CFrame).
function DodgeballBallTemplate.applyAppearance(part: BasePart)
	local diameter = ballDiameter()
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter, diameter, diameter)

	local color = Config.BALL_COLOR
	if typeof(color) == "Color3" then
		part.Color = color
	end

	local material = Config.BALL_MATERIAL
	if typeof(material) == "EnumItem" and material.EnumType == Enum.Material then
		part.Material = material
	end

	applyPhysicalProperties(part)
	ensurePhysicsTrackingTag(part)
end

function DodgeballBallTemplate.createPart(): BasePart
	local part = Instance.new("Part")
	local name = Config.BALL_PART_NAME
	if typeof(name) == "string" and name ~= "" then
		part.Name = name
	end
	DodgeballBallTemplate.applyAppearance(part)
	part.Anchored = false
	part.CanCollide = true
	part.CanTouch = true
	return part
end

function DodgeballBallTemplate.halfHeight(): number
	return ballDiameter() * 0.5
end

return DodgeballBallTemplate
