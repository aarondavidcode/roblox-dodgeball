-- Paste as LocalScript named RoundStatusClient inside StarterGui/RoundStatus
-- Parent ScreenGui must be named RoundStatus; label must be CountdownLabel (Text = empty).

--!strict

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

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

local function refresh()
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
			label.Text = "Lobby — waiting for another player…"
		elseif typeof(endsAt) == "number" then
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			label.Text = `Lobby — match starts in {left}s`
		else
			label.Text = "Lobby — waiting for another player…"
		end
		return
	end

	if matchPhase ~= "InMatch" then
		label.Text = "…"
		return
	end

	local scores = matchScoreText()

	if roundState == "Intermission" then
		local endsAt = folder:GetAttribute("IntermissionEndsAt")
		if typeof(endsAt) == "number" then
			local left = math.max(0, math.ceil(endsAt - workspace:GetServerTimeNow()))
			label.Text = `{scores} · Round {roundNum} soon ({left}s)`
		else
			label.Text = `{scores} · Round break…`
		end
	elseif roundState == "Resetting" then
		label.Text = `{scores} · Resetting arena…`
	elseif roundState == "Playing" then
		label.Text = `{scores} · Round {roundNum} — PLAY!`
	else
		label.Text = `{scores} · Round {roundNum}`
	end
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