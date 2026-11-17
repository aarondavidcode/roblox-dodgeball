-- Studio setup: BallVisualEffectShell.md
-- Transparent non-colliding sphere welded to a dodgeball for larger client-only VFX (Highlight, etc.).

--!strict

local BallVisualEffectShell = {}

export type ShellHandle = {
	part: BasePart,
	setDiameterScale: (scale: number) -> (),
	setGlowActive: (active: boolean) -> (),
	destroy: () -> (),
}

local function ballDiameterStuds(ball: BasePart): number
	return math.max(ball.Size.X, ball.Size.Y, ball.Size.Z)
end

local function applyShellSize(shell: BasePart, ball: BasePart, diameterScale: number)
	local base = ballDiameterStuds(ball)
	local diameter = base * diameterScale
	shell.Size = Vector3.new(diameter, diameter, diameter)
end

function BallVisualEffectShell.create(ball: BasePart, effectLabel: string, diameterScale: number): ShellHandle?
	if ball.Shape ~= Enum.PartType.Ball then
		return nil
	end
	if diameterScale <= 0 then
		diameterScale = 1
	end

	local shell = Instance.new("Part")
	shell.Name = `BallVisualEffectShell_{effectLabel}`
	shell.Shape = Enum.PartType.Ball
	shell.Material = Enum.Material.SmoothPlastic
	shell.Color = ball.Color
	shell.Transparency = 1
	shell.Anchored = false
	shell.Massless = true
	shell.CanCollide = false
	shell.CanTouch = false
	shell.CanQuery = false
	shell.CastShadow = false
	applyShellSize(shell, ball, diameterScale)
	shell.CFrame = ball.CFrame
	shell.Parent = ball

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = shell
	weld.Parent = shell

	local destroyed = false

	local handle: ShellHandle = {
		part = shell,
		setDiameterScale = function(scale: number)
			if destroyed then
				return
			end
			if scale <= 0 then
				scale = 1
			end
			applyShellSize(shell, ball, scale)
		end,
		setGlowActive = function(active: boolean)
			if destroyed then
				return
			end
			if active then
				shell.Material = Enum.Material.ForceField
				shell.Transparency = 0.88
			else
				shell.Material = Enum.Material.SmoothPlastic
				shell.Transparency = 1
			end
		end,
		destroy = function()
			if destroyed then
				return
			end
			destroyed = true
			shell:Destroy()
		end,
	}

	return handle
end

return BallVisualEffectShell
