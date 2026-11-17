-- Studio setup: BallPhysicsResolver.md
-- Paste as ModuleScript BallPhysicsResolver under ReplicatedStorage (server + client require).

--!strict

local BallPhysicsResolver = {}

export type ResolveResult = {
	module: ModuleScript?,
	layout: string,
}

-- Returns the library entry ModuleScript (init) and a layout tag for logs.
function BallPhysicsResolver.resolve(parent: Instance): ResolveResult
	local inst = parent:FindFirstChild("BallPhysics")
	if not inst then
		return { module = nil, layout = "missing" }
	end

	if inst:IsA("ModuleScript") then
		if inst:FindFirstChild("Config") then
			return { module = inst, layout = "ModuleScript-root" }
		end
		return { module = inst, layout = "ModuleScript-root-missing-Config-child" }
	end

	if inst:IsA("Folder") then
		local nested = inst:FindFirstChild("BallPhysics")
		if nested and nested:IsA("ModuleScript") and nested:FindFirstChild("Config") then
			return { module = nested, layout = "Folder/BallPhysics-nested" }
		end
		local initChild = inst:FindFirstChild("init")
		if initChild and initChild:IsA("ModuleScript") and initChild:FindFirstChild("Config") then
			return { module = initChild, layout = "Folder/init-with-Config-under-init" }
		end
		if inst:FindFirstChild("Config") then
			return {
				module = nil,
				layout = "Folder-flat-children-move-into-ModuleScript-root",
			}
		end
		return { module = nil, layout = "Folder-wrong" }
	end

	return { module = nil, layout = `invalid-type-{inst.ClassName}` }
end

function BallPhysicsResolver.describeExpected(): string
	return "ReplicatedStorage/BallPhysics = ModuleScript (paste init.luau); Config/Effects/Runtime as children of that ModuleScript — NOT a Folder named BallPhysics"
end

return BallPhysicsResolver
