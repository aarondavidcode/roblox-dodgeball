-- Studio setup: DodgeballMatchNpc.md
-- Server registry for Studio single-player test NPCs (see DodgeballSinglePlayerTest + DodgeballDebugConfig).

--!strict

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local Config = require(ServerScriptService:WaitForChild("DodgeballConfig"))

export type NpcRecord = {
	sortId: number,
	teamName: string?,
	isOut: boolean,
	matchParticipant: boolean,
	model: Model?,
	walkToken: number,
}

local ATTR_IS_NPC = "DodgeballTestNpc"
local NPC_TAG = "DodgeballTestNpc"
local ATTR_TEAM_NAME = "MatchTeamName"
local ATTR_IS_OUT = "IsOut"
local ATTR_MATCH_PARTICIPANT = "MatchParticipant"
local ATTR_SORT_ID = "NpcSortId"
local FOLDER_NAME = "DodgeballTestNpcs"

local SPAWN_Y_OFFSET = 4
local WALK_RADIUS = 36

local npcRecords: { NpcRecord } = {}
local npcFolder: Folder? = nil
local randomWalkRunning = false

local DodgeballMatchNpc = {}

local function ensureFolder(): Folder
	if npcFolder and npcFolder.Parent then
		return npcFolder
	end
	local existing = Workspace:FindFirstChild(FOLDER_NAME)
	if existing and existing:IsA("Folder") then
		npcFolder = existing
		return existing
	end
	local folder = Instance.new("Folder")
	folder.Name = FOLDER_NAME
	folder.Parent = Workspace
	npcFolder = folder
	return folder
end

local function isLobbySpawn(spawn: SpawnLocation): boolean
	local name = Config.LOBBY_SPAWN_NAME
	if typeof(name) == "string" and name ~= "" and spawn.Name == name then
		return true
	end
	local tag = Config.LOBBY_SPAWN_TAG
	if typeof(tag) == "string" and tag ~= "" and CollectionService:HasTag(spawn, tag) then
		return true
	end
	return false
end

local function findTeamSpawnLocation(teamName: string): SpawnLocation?
	local team = Teams:FindFirstChild(teamName)
	if not team or not team:IsA("Team") then
		return nil
	end
	for _, descendant in Workspace:GetDescendants() do
		if descendant:IsA("SpawnLocation") and not isLobbySpawn(descendant) then
			if descendant.Neutral == false and descendant.TeamColor == team.TeamColor then
				return descendant
			end
		end
	end
	return nil
end

local function findOpposingTeamSpawnLocation(teamName: string): SpawnLocation?
	for _, otherName in Config.TEAM_NAMES do
		if typeof(otherName) == "string" and otherName ~= teamName then
			return findTeamSpawnLocation(otherName)
		end
	end
	return nil
end

local function arenaCFrameForTeam(teamName: string): CFrame?
	local spawn = findTeamSpawnLocation(teamName)
	if not spawn then
		return nil
	end
	local pos = spawn.CFrame.Position + Vector3.new(0, SPAWN_Y_OFFSET, 0)
	local opposing = findOpposingTeamSpawnLocation(teamName)
	if opposing then
		local target = opposing.CFrame.Position
		local lookAt = Vector3.new(target.X, pos.Y, target.Z)
		if (lookAt - pos).Magnitude > 0.5 then
			return CFrame.lookAt(pos, lookAt)
		end
	end
	return spawn.CFrame + Vector3.new(0, SPAWN_Y_OFFSET, 0)
end

local function applyRecordAttributes(model: Model, record: NpcRecord)
	model:SetAttribute(ATTR_IS_NPC, true)
	model:SetAttribute(ATTR_SORT_ID, record.sortId)
	model:SetAttribute(ATTR_IS_OUT, record.isOut)
	model:SetAttribute(ATTR_MATCH_PARTICIPANT, record.matchParticipant)
	if record.teamName then
		model:SetAttribute(ATTR_TEAM_NAME, record.teamName)
	else
		model:SetAttribute(ATTR_TEAM_NAME, nil)
	end
	CollectionService:AddTag(model, NPC_TAG)
end

local function createNpcModel(record: NpcRecord): Model?
	local ok, model = pcall(function()
		return Players:CreateHumanoidModelFromUserId(156)
	end)
	if not ok or not model or not model:IsA("Model") then
		warn("[DodgeballMatchNpc] Failed to create humanoid model for test NPC.")
		return nil
	end
	model.Name = `TestNpc_{-record.sortId}`
	applyRecordAttributes(model, record)
	local humanoid = model:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	end
	model.Parent = ensureFolder()
	return model
end

local function destroyModel(model: Model?)
	if model and model.Parent then
		model:Destroy()
	end
end

function DodgeballMatchNpc.getActiveCount(): number
	return #npcRecords
end

function DodgeballMatchNpc.getRecords(): { NpcRecord }
	return npcRecords
end

function DodgeballMatchNpc.destroyAll()
	for _, record in npcRecords do
		destroyModel(record.model)
	end
	table.clear(npcRecords)
end

function DodgeballMatchNpc.spawnMany(count: number): boolean
	DodgeballMatchNpc.destroyAll()
	if count < 1 then
		return false
	end
	local folder = ensureFolder()
	for i = 1, count do
		local record: NpcRecord = {
			sortId = -i,
			teamName = nil,
			isOut = false,
			matchParticipant = false,
			model = nil,
			walkToken = 0,
		}
		local model = createNpcModel(record)
		if not model then
			DodgeballMatchNpc.destroyAll()
			return false
		end
		record.model = model
		table.insert(npcRecords, record)
	end
	folder:SetAttribute("NpcCount", #npcRecords)
	warn(`[DodgeballMatchNpc] Spawned {#npcRecords} test NPC(s).`)
	return true
end

function DodgeballMatchNpc.npcFromPart(part: BasePart): Model?
	local model = part:FindFirstAncestorOfClass("Model")
	if not model then
		return nil
	end
	if model:GetAttribute(ATTR_IS_NPC) == true then
		return model
	end
	return nil
end

function DodgeballMatchNpc.getTeamName(npc: Model): string?
	local onModel = npc:GetAttribute(ATTR_TEAM_NAME)
	if typeof(onModel) == "string" and onModel ~= "" then
		return onModel
	end
	for _, record in npcRecords do
		if record.model == npc then
			return record.teamName
		end
	end
	return nil
end

function DodgeballMatchNpc.isMatchParticipant(npc: Model): boolean
	if npc:GetAttribute(ATTR_MATCH_PARTICIPANT) == true then
		return true
	end
	for _, record in npcRecords do
		if record.model == npc then
			return record.matchParticipant
		end
	end
	return false
end

function DodgeballMatchNpc.isOut(npc: Model): boolean
	if npc:GetAttribute(ATTR_IS_OUT) == true then
		return true
	end
	for _, record in npcRecords do
		if record.model == npc and record.isOut then
			return true
		end
	end
	return false
end

function DodgeballMatchNpc.setTeamName(npc: Model, teamName: string)
	for _, record in npcRecords do
		if record.model == npc then
			record.teamName = teamName
			npc:SetAttribute(ATTR_TEAM_NAME, teamName)
			local team = Teams:FindFirstChild(teamName)
			if team and team:IsA("Team") then
				local humanoid = npc:FindFirstChildOfClass("Humanoid")
				if humanoid then
					humanoid.TeamColor = team.TeamColor
				end
			end
			return
		end
	end
end

local function fireEliminatedBridge()
	local bridge = ServerScriptService:FindFirstChild("DodgeballRoundBridge")
	if not bridge then
		return
	end
	local ev = bridge:FindFirstChild("PlayerEliminated")
	if ev and ev:IsA("BindableEvent") then
		ev:Fire()
	end
end

function DodgeballMatchNpc.eliminate(npc: Model)
	if DodgeballMatchNpc.isOut(npc) then
		return
	end
	for _, record in npcRecords do
		if record.model == npc then
			record.isOut = true
			record.walkToken += 1
			npc:SetAttribute(ATTR_IS_OUT, true)
			local humanoid = npc:FindFirstChildOfClass("Humanoid")
			if humanoid and humanoid.Health > 0 then
				humanoid.Health = 0
			end
			task.defer(function()
				destroyModel(record.model)
				record.model = nil
			end)
			warn(`[DodgeballMatchNpc] {npc.Name} is OUT.`)
			fireEliminatedBridge()
			return
		end
	end
end

function DodgeballMatchNpc.clearAllOuts()
	for _, record in npcRecords do
		record.isOut = false
		record.walkToken += 1
		if not record.model or not record.model.Parent then
			record.model = createNpcModel(record)
		end
		if record.model then
			record.model:SetAttribute(ATTR_IS_OUT, false)
		end
	end
end

function DodgeballMatchNpc.setAllMatchParticipants(participating: boolean)
	for _, record in npcRecords do
		record.matchParticipant = participating
		record.isOut = false
		if record.model then
			record.model:SetAttribute(ATTR_MATCH_PARTICIPANT, participating)
			record.model:SetAttribute(ATTR_IS_OUT, false)
		end
	end
end

local function teleportRecordToArena(record: NpcRecord)
	if record.isOut or not record.matchParticipant or not record.teamName then
		return
	end
	if not record.model or not record.model.Parent then
		record.model = createNpcModel(record)
	end
	local model = record.model
	if not model then
		return
	end
	local cf = arenaCFrameForTeam(record.teamName)
	if not cf then
		warn(`[DodgeballMatchNpc] No arena spawn for team {record.teamName}.`)
		return
	end
	local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
	if hrp then
		model:PivotTo(cf)
	end
end

function DodgeballMatchNpc.spawnAllAtTeamArenas()
	for _, record in npcRecords do
		teleportRecordToArena(record)
	end
end

function DodgeballMatchNpc.respawnActiveAtTeamArenas()
	for _, record in npcRecords do
		if record.isOut then
			continue
		end
		if not record.model or not record.model.Parent then
			record.model = createNpcModel(record)
			applyRecordAttributes(record.model, record)
		end
		teleportRecordToArena(record)
	end
end

local function randomWalkPoint(origin: Vector3): Vector3
	local angle = math.random() * math.pi * 2
	local dist = WALK_RADIUS * (0.25 + math.random() * 0.75)
	return origin + Vector3.new(math.cos(angle) * dist, 0, math.sin(angle) * dist)
end

local function runRandomWalkLoop()
	if randomWalkRunning then
		return
	end
	randomWalkRunning = true
	task.spawn(function()
		while #npcRecords > 0 do
			for _, record in npcRecords do
				if record.isOut or not record.matchParticipant then
					continue
				end
				local model = record.model
				if not model or not model.Parent then
					continue
				end
				local humanoid = model:FindFirstChildOfClass("Humanoid")
				local hrp = model:FindFirstChild("HumanoidRootPart") :: BasePart?
				if not humanoid or not hrp or humanoid.Health <= 0 then
					continue
				end
				record.walkToken += 1
				local token = record.walkToken
				local target = randomWalkPoint(hrp.Position)
				humanoid:MoveTo(target)
				task.wait(1.5 + math.random() * 2.5)
				if record.walkToken ~= token then
					continue
				end
			end
			task.wait(0.35)
		end
		randomWalkRunning = false
	end)
end

function DodgeballMatchNpc.beginRandomWalk()
	runRandomWalkLoop()
end

function DodgeballMatchNpc.isNpcModel(model: Model): boolean
	return model:GetAttribute(ATTR_IS_NPC) == true
end

function DodgeballMatchNpc.forEachActiveNpc(callback: (Model, NpcRecord) -> ())
	for _, record in npcRecords do
		if record.matchParticipant and not record.isOut and record.model and record.model.Parent then
			callback(record.model, record)
		end
	end
end

function DodgeballMatchNpc.teamHasParticipant(teamName: string): boolean
	for _, record in npcRecords do
		if record.matchParticipant and record.teamName == teamName then
			return true
		end
	end
	return false
end

function DodgeballMatchNpc.teamHasActiveMember(teamName: string): boolean
	for _, record in npcRecords do
		if record.matchParticipant and not record.isOut and record.teamName == teamName then
			return true
		end
	end
	return false
end

function DodgeballMatchNpc.isTeamFullyOut(teamName: string): boolean
	local hasMember = false
	for _, record in npcRecords do
		if record.matchParticipant and record.teamName == teamName then
			hasMember = true
			if not record.isOut then
				return false
			end
		end
	end
	return hasMember
end

function DodgeballMatchNpc.allParticipantsOut(): boolean
	local any = false
	for _, record in npcRecords do
		if not record.matchParticipant then
			continue
		end
		any = true
		if not record.isOut then
			return false
		end
	end
	return any
end

return DodgeballMatchNpc