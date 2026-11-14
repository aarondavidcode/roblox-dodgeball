-- Paste as LocalScript named RoundStatusClient inside StarterGui/RoundStatus
-- Parent ScreenGui must be named RoundStatus; label must be CountdownLabel (Text = empty).

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local gui = script.Parent
if not gui:IsA("ScreenGui") then
	warn("[RoundStatusClient] Parent must be the RoundStatus ScreenGui.")
	return
end

local label = gui:WaitForChild("CountdownLabel", 10) :: TextLabel?
if not label then
	warn("[RoundStatusClient] Missing TextLabel named CountdownLabel under RoundStatus.")
	return
end

local folder = ReplicatedStorage:WaitForChild("RoundStatus", 30)
if not folder then
	warn("[RoundStatusClient] RoundStatus folder missing — are LobbyService and RoundService running?")
	return
end

local TEAM_NAMES = { "Red", "Blue" }

local FADE_DELAY_SECONDS = 3
local FADE_OUT_SECONDS = 0.35
local FADE_IN_SECONDS = 0.15

local shownText = ""
local stableFadeGeneration = 0
local activeFadeTween: Tween? = nil

local function labelStrokes(): { UIStroke }
	local strokes: { UIStroke } = {}
	for _, child in label:GetChildren() do
		if child:IsA("UIStroke") then
			table.insert(strokes, child)
		end
	end
	return strokes
end

local function cancelFadeTween()
	if activeFadeTween then
		activeFadeTween:Cancel()
		activeFadeTween = nil
	end
end

local function tweenLabelTransparency(target: number, duration: number)
	cancelFadeTween()
	local strokes = labelStrokes()
	local goals: { [string]: number } = { TextTransparency = target }
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweens: { Tween } = {}
	table.insert(tweens, TweenService:Create(label, tweenInfo, goals))
	for _, stroke in strokes do
		table.insert(tweens, TweenService:Create(stroke, tweenInfo, { Transparency = target }))
	end
	activeFadeTween = tweens[1]
	for _, tween in tweens do
		tween:Play()
	end
end

local function showLabel(fadeIn: boolean)
	cancelFadeTween()
	if fadeIn then
		tweenLabelTransparency(0, FADE_IN_SECONDS)
	else
		label.TextTransparency = 0
		for _, stroke in labelStrokes() do
			stroke.Transparency = 0
		end
	end
end

local function scheduleFadeAfterStable(displayText: string)
	stableFadeGeneration += 1
	local generation = stableFadeGeneration
	task.delay(FADE_DELAY_SECONDS, function()
		if generation ~= stableFadeGeneration then
			return
		end
		if label.Text ~= displayText then
			return
		end
		tweenLabelTransparency(1, FADE_OUT_SECONDS)
	end)
end

local function commitLabelText(newText: string)
	if newText == shownText then
		return
	end
	shownText = newText
	label.Text = newText
	showLabel(true)
	scheduleFadeAfterStable(newText)
end

local function matchScoreText(): string
	local parts: { string } = {}
	for _, teamName in TEAM_NAMES do
		local score = folder:GetAttribute(`MatchScore_{teamName}`)
		if typeof(score) ~= "number" then
			score = 0
		end
		table.insert(parts, `{teamName} {score}`)
	end
	local toWin = folder:GetAttribute("MatchPointsToWin")
	if typeof(toWin) ~= "number" then
		toWin = 3
	end
	return table.concat(parts, " · ") .. ` (first {toWin})`
end

local function buildStatusText(): string
	local matchPhase = folder:GetAttribute("MatchPhase")
	if typeof(matchPhase) ~= "string" then
		matchPhase = "Lobby"
	end

	local roundState = folder:GetAttribute("RoundState")
	if typeof(roundState) ~= "string" then
		roundState = "LobbyIdle"
	end

	local roundNum = folder:GetAttribute("RoundNumber")
	if typeof(roundNum) ~= "number" then
		roundNum = 1
	end

	if matchPhase == "Lobby" then
		local endsAt = folder:GetAttribute("LobbyCountdownEndsAt")
		if #Players:GetPlayers() < 2 then
			return "Lobby — waiting for another player…"
		elseif typeof(endsAt) == "number" then
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			return `Lobby — match starts in {left}s`
		else
			return "Lobby — waiting for another player…"
		end
	end

	if matchPhase ~= "InMatch" then
		return "…"
	end

	local scores = matchScoreText()

	if roundState == "Intermission" then
		local endsAt = folder:GetAttribute("IntermissionEndsAt")
		if typeof(endsAt) == "number" then
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			return `{scores} · Round {roundNum} soon ({left}s)`
		else
			return `{scores} · Round break…`
		end
	elseif roundState == "Resetting" then
		return `{scores} · Resetting arena…`
	elseif roundState == "Playing" then
		return `{scores} · Round {roundNum} — PLAY!`
	else
		return `{scores} · Round {roundNum}`
	end
end

local function refresh()
	commitLabelText(buildStatusText())
end

for _, name in {
	"MatchPhase",
	"MatchScore_Red",
	"MatchScore_Blue",
	"MatchPointsToWin",
	"LobbyCountdownEndsAt",
	"RoundState",
	"RoundNumber",
	"IntermissionEndsAt",
} do
	folder:GetAttributeChangedSignal(name):Connect(refresh)
end

Players.PlayerAdded:Connect(refresh)
Players.PlayerRemoving:Connect(refresh)

task.spawn(function()
	while true do
		refresh()
		task.wait(0.25)
	end
end)

refresh()