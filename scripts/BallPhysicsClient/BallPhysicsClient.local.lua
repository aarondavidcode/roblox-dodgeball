-- Studio setup: BallPhysicsClient.md
-- Client singleton for BallPhysics ownership replication (required for client-owned ball sim).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local PREFIX = "[DodgeballBallPhysicsDebug]"

local player = Players.LocalPlayer

local function debugEnabled(): boolean
	local folder = ReplicatedStorage:FindFirstChild("DodgeballRemotes")
	return folder ~= nil and folder:IsA("Folder") and folder:GetAttribute("DEBUG_BALL_PHYSICS") == true
end

local function debugLog(message: string)
	if not debugEnabled() then
		return
	end
	print(`{PREFIX} {message}`)
end

local function debugWarn(message: string)
	if not debugEnabled() then
		return
	end
	warn(`{PREFIX} {message}`)
end

local LAYOUT_HINT = "ReplicatedStorage/BallPhysics must be a ModuleScript with Config child — not a Folder"
local entry = ReplicatedStorage:FindFirstChild("BallPhysics")
if not entry then
	debugWarn(`BallPhysics missing — {LAYOUT_HINT}`)
	entry = ReplicatedStorage:WaitForChild("BallPhysics", 120)
end
if entry:IsA("Folder") then
	debugWarn(`BallPhysics is a Folder (cannot require) — {LAYOUT_HINT}`)
	return
end
if not entry:IsA("ModuleScript") then
	debugWarn(`BallPhysics is a {entry.ClassName}, expected ModuleScript — {LAYOUT_HINT}`)
	return
end
if not entry:FindFirstChild("Config") then
	debugWarn(`BallPhysics has no Config child — {LAYOUT_HINT}`)
	return
end

local ok, BallPhysics = pcall(require, entry)
if not ok or typeof(BallPhysics) ~= "table" or typeof(BallPhysics.new) ~= "function" then
	debugWarn(`BallPhysics client require failed err={tostring(BallPhysics)}`)
	return
end

BallPhysics.new()
debugLog("BallPhysicsClient singleton started (ModuleScript root)")

local physicsTag = "PhysicsBall"
local lastSampledThrowTime: { [BasePart]: number } = {}

local function watchBallThrowSample(ball: BasePart)
	if not debugEnabled() then
		return
	end
	if lastSampledThrowTime[ball] then
		return
	end
	ball:GetAttributeChangedSignal("LastThrowTime"):Connect(function()
		if not debugEnabled() then
			return
		end
		local throwTime = ball:GetAttribute("LastThrowTime")
		local throwerId = ball:GetAttribute("LastThrowerUserId")
		if typeof(throwTime) ~= "number" or throwTime <= 0 then
			return
		end
		if typeof(throwerId) ~= "number" or throwerId ~= player.UserId then
			return
		end
		if lastSampledThrowTime[ball] == throwTime then
			return
		end
		lastSampledThrowTime[ball] = throwTime

		task.delay(0.35, function()
			if not ball.Parent then
				return
			end
			local owned = BallPhysics.isOwned(ball)
			debugLog(
				`client+0.35s ball={ball.Name} BallPhysics.isOwned={owned} lin={string.format(
					"%.2f",
					ball.AssemblyLinearVelocity.Magnitude
				)} ang={string.format("%.2f", ball.AssemblyAngularVelocity.Magnitude)}`
			)
		end)
		task.delay(2, function()
			if not ball.Parent then
				return
			end
			local owned = BallPhysics.isOwned(ball)
			debugLog(
				`client+2s ball={ball.Name} BallPhysics.isOwned={owned} lin={string.format(
					"%.2f",
					ball.AssemblyLinearVelocity.Magnitude
				)} ang={string.format("%.2f", ball.AssemblyAngularVelocity.Magnitude)}`
			)
		end)
	end)
end

if debugEnabled() then
	for _, inst in CollectionService:GetTagged(physicsTag) do
		if inst:IsA("BasePart") then
			watchBallThrowSample(inst)
		end
	end
	CollectionService:GetInstanceAddedSignal(physicsTag):Connect(function(inst: Instance)
		if inst:IsA("BasePart") then
			watchBallThrowSample(inst)
		end
	end)
end

task.spawn(function()
	local remotes = ReplicatedStorage:WaitForChild("DodgeballRemotes", 60)
	if remotes and remotes:IsA("Folder") then
		remotes:GetAttributeChangedSignal("DEBUG_BALL_PHYSICS"):Connect(function()
			if debugEnabled() then
				debugLog("client debug enabled via DodgeballRemotes attribute")
			end
		end)
	end
end)
