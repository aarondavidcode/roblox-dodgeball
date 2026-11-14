-- Paste as ModuleScript DefaultThrow under ServerScriptService → throw (folder).
-- This is the normal throw. Swap ACTIVE_THROW_PROFILE in DodgeballConfig for other modules later.

--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

export type ThrowContext = {
	ball: BasePart,
	thrower: Player,
	direction: Vector3, -- unit vector, already checked on the server
	powerMultiplier: number?, -- 0–1 from aim charge; defaults to 1
}

local DefaultThrow = {}

DefaultThrow.name = "Default"

-- Apply impulse and remember who threw (for out rules).
function DefaultThrow.throw(_self: typeof(DefaultThrow), context: ThrowContext)
	local ball = context.ball
	local direction = context.direction.Unit
	local power = context.powerMultiplier
	if typeof(power) ~= "number" then
		power = 1
	end
	power = math.clamp(power, 0.05, 1)

	local mass = ball.AssemblyMass
	local impulse = direction * Config.THROW_IMPULSE * mass * power

	ball:ApplyImpulse(impulse)

	local now = workspace:GetServerTimeNow()
	-- Impulse = direction * THROW_IMPULSE * mass * power → speed magnitude ≈ THROW_IMPULSE * power.
	local estimatedSpeed = Config.THROW_IMPULSE * power
	ball:SetAttribute("LastThrowTime", now)
	ball:SetAttribute("LastThrowerUserId", context.thrower.UserId)
	ball:SetAttribute("LastThrowSpeed", estimatedSpeed)
	ball:SetAttribute("InThrowWindow", true)
end

-- Hook for future “special throws” (curve, mega throw, etc.)—return extra data the service can read.
function DefaultThrow.onThrowStarted(_self: typeof(DefaultThrow), _context: ThrowContext): { [string]: any }?
	return nil
end

return DefaultThrow