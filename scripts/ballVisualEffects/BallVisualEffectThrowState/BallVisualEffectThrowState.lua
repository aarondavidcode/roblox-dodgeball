-- Studio setup: BallVisualEffectThrowState.md
-- Shared client rules: when a ball is in the "can still eliminate" state (matches DodgeballService.isLiveThrow).
-- All ball visual effects should gate on these helpers, not ad-hoc LastThrowTime / speed checks.

--!strict

local Registry = require(script.Parent:WaitForChild("BallVisualEffectRegistry"))

local BallVisualEffectThrowState = {}

local function throwOutWindowSeconds(windowSeconds: number): number
	if typeof(windowSeconds) ~= "number" or windowSeconds <= 0 then
		return 3
	end
	return windowSeconds
end

function BallVisualEffectThrowState.isBallHeld(ball: BasePart): boolean
	local holderId = ball:GetAttribute("HolderUserId")
	return typeof(holderId) == "number" and holderId > 0
end

-- Mirrors DodgeballService.isLiveThrow (InThrowWindow is cleared when speed < HIT_MIN_SPEED or throw ends).
function BallVisualEffectThrowState.canStillEliminate(ball: BasePart, windowSeconds: number): boolean
	local throwTime = ball:GetAttribute("LastThrowTime")
	local throwerId = ball:GetAttribute("LastThrowerUserId")
	if typeof(throwTime) ~= "number" or typeof(throwerId) ~= "number" then
		return false
	end
	if throwTime <= 0 then
		return false
	end
	local elapsed = workspace:GetServerTimeNow() - throwTime
	if elapsed < 0 or elapsed > throwOutWindowSeconds(windowSeconds) then
		return false
	end
	return ball:GetAttribute("InThrowWindow") == true
end

-- Base gate: effect may run only on a live elimination throw (not carried, server InThrowWindow).
function BallVisualEffectThrowState.shouldShowForLiveEliminationThrow(
	ball: BasePart,
	context: Registry.EffectContext
): boolean
	if BallVisualEffectThrowState.isBallHeld(ball) then
		return false
	end
	return BallVisualEffectThrowState.canStillEliminate(ball, context.throwOutWindowSeconds)
end

-- Client physics can under-report speed; server replicates LastThrowSpeed while InThrowWindow is true.
function BallVisualEffectThrowState.resolveEffectiveThrowSpeed(ball: BasePart, context: Registry.EffectContext): number
	local measured = ball.AssemblyLinearVelocity.Magnitude
	local threshold = context.hitMinSpeed
	if measured >= threshold then
		return measured
	end
	if not BallVisualEffectThrowState.canStillEliminate(ball, context.throwOutWindowSeconds) then
		return measured
	end
	local lastThrow = ball:GetAttribute("LastThrowSpeed")
	if typeof(lastThrow) ~= "number" or lastThrow < threshold then
		return measured
	end
	local offThreshold = threshold * context.speedGlowHysteresisFraction
	if measured < offThreshold then
		return measured
	end
	return math.max(measured, lastThrow)
end

function BallVisualEffectThrowState.hitSpeedOffThreshold(context: Registry.EffectContext): number
	return context.hitMinSpeed * context.speedGlowHysteresisFraction
end

-- Hysteresis for effects that also require HIT_MIN_SPEED (e.g. SpeedGlow).
function BallVisualEffectThrowState.isAboveHitSpeedWithHysteresis(
	speed: number,
	context: Registry.EffectContext,
	currentlyActive: boolean
): boolean
	local onThreshold = context.hitMinSpeed
	local offThreshold = BallVisualEffectThrowState.hitSpeedOffThreshold(context)
	if currentlyActive then
		return speed >= offThreshold
	end
	return speed >= onThreshold
end

return BallVisualEffectThrowState