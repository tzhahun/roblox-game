local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Knockback = require(ReplicatedStorage.Shared.Knockback)
local Arena = require(script.Parent.Arena)
local OrbFactory = require(script.Parent.OrbFactory)
local Remotes = require(script.Parent.Remotes)

local RoundManager = {}

local alive: { [Player]: boolean } = {}
local lastBump: { [string]: number } = {}
local roundActive = false

local function broadcast(message: string, aliveCount: number?)
	Remotes.GameState:FireAllClients({
		message = message,
		alive = aliveCount,
		roundActive = roundActive,
	})
end

local function countAlive(): number
	local n = 0
	for _, isAlive in alive do
		if isAlive then
			n += 1
		end
	end
	return n
end

local function getAlivePlayers(): { Player }
	local list = {}
	for player, isAlive in alive do
		if isAlive and player.Parent then
			table.insert(list, player)
		end
	end
	return list
end

function RoundManager.isPlayerAlive(player: Player): boolean
	return alive[player] == true
end

function RoundManager.eliminate(player: Player, reason: string)
	if not alive[player] then
		return
	end
	alive[player] = false

	local character = player.Character
	if character then
		character:Destroy()
	end

	local remaining = countAlive()
	broadcast(`{player.DisplayName} fell off! ({remaining} left)`, remaining)

	if roundActive and remaining <= 1 then
		task.defer(RoundManager.endRound)
	end
end

function RoundManager.spawnPlayer(player: Player, slot: number, total: number)
	if not alive[player] then
		return
	end

	local model = OrbFactory.create(player)
	model:PivotTo(Arena.getSpawnCFrame(slot, total))
	model.Parent = workspace
	player.Character = model
end

function RoundManager.startRound()
	roundActive = true
	Arena.ensure()

	local players = Players:GetPlayers()
	table.sort(players, function(a, b)
		return a.UserId < b.UserId
	end)

	if #players < GameConfig.MIN_PLAYERS_TO_START then
		broadcast(`Waiting for players… ({#players}/{GameConfig.MIN_PLAYERS_TO_START})`, 0)
		return
	end

	for _, player in players do
		alive[player] = true
	end

	for index, player in players do
		RoundManager.spawnPlayer(player, index, #players)
	end

	broadcast("Fight! Knock the other orbs off the platform!", countAlive())
end

function RoundManager.endRound()
	if not roundActive then
		return
	end
	roundActive = false

	local winners = getAlivePlayers()
	local message: string
	if #winners == 1 then
		message = `{winners[1].DisplayName} wins!`
	elseif #winners == 0 then
		message = "Round over — no winner!"
	else
		message = "Round over!"
	end

	broadcast(message, 0)

	task.wait(GameConfig.ROUND_INTERMISSION)
	RoundManager.startRound()
end

function RoundManager.setupCollisions()
	RunService.Heartbeat:Connect(function()
		if not roundActive then
			return
		end

		local fallY = Arena.getFallY()
		local now = os.clock()

		for _, player in Players:GetPlayers() do
			if not alive[player] then
				continue
			end

			local character = player.Character
			if not character or not character.PrimaryPart then
				continue
			end

			if character.PrimaryPart.Position.Y < fallY then
				RoundManager.eliminate(player, "fell")
			end
		end
	end)

	local function tryBump(partA: BasePart, partB: BasePart)
		local modelA = OrbFactory.getOrbFromPart(partA)
		local modelB = OrbFactory.getOrbFromPart(partB)
		if not modelA or not modelB or modelA == modelB then
			return
		end

		local key = modelA:GetFullName() .. "|" .. modelB:GetFullName()
		local bumpNow = os.clock()
		local last = lastBump[key]
		if last and bumpNow - last < GameConfig.BUMP_COOLDOWN then
			return
		end

		local impulseA, impulseB = Knockback.computeBump(
			partA.AssemblyLinearVelocity,
			partB.AssemblyLinearVelocity,
			partA.Position,
			partB.Position
		)
		if not impulseA or not impulseB then
			return
		end

		lastBump[key] = bumpNow
		partA.AssemblyLinearVelocity += impulseA
		partB.AssemblyLinearVelocity += impulseB
	end

	local function hookPart(part: BasePart)
		part.Touched:Connect(function(other)
			if other:IsA("BasePart") then
				tryBump(part, other)
			end
		end)
	end

	local function onCharacterAdded(character: Model)
		if not OrbFactory.isOrbModel(character) then
			return
		end
		for _, descendant in character:GetDescendants() do
			if descendant:IsA("BasePart") then
				hookPart(descendant)
			end
		end
		if character.PrimaryPart then
			hookPart(character.PrimaryPart)
		end
	end

	Players.PlayerAdded:Connect(function(player)
		alive[player] = false
		player.CharacterAdded:Connect(onCharacterAdded)
		if roundActive then
			task.wait(0.5)
			if not roundActive then
				return
			end
			alive[player] = true
			local total = countAlive()
			RoundManager.spawnPlayer(player, total, total)
			broadcast(`{player.DisplayName} joined the round!`, countAlive())
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		alive[player] = nil
		if roundActive and countAlive() <= 1 then
			task.defer(RoundManager.endRound)
		end
	end)

	for _, player in Players:GetPlayers() do
		player.CharacterAdded:Connect(onCharacterAdded)
	end
end

function RoundManager.setupDash()
	Remotes.Dash.OnServerEvent:Connect(function(player)
		if not roundActive or not alive[player] then
			return
		end

		local character = player.Character
		if not character or not character.PrimaryPart then
			return
		end

		local lastDash = player:GetAttribute("LastDash") or 0
		if os.clock() - lastDash < GameConfig.DASH_COOLDOWN then
			return
		end
		player:SetAttribute("LastDash", os.clock())

		local root = character.PrimaryPart
		local direction = root.AssemblyLinearVelocity
		if direction.Magnitude < 2 then
			direction = root.CFrame.LookVector
		end
		direction = Vector3.new(direction.X, 0, direction.Z)
		if direction.Magnitude < 0.1 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end

		root.AssemblyLinearVelocity += direction * GameConfig.DASH_POWER + Vector3.new(0, 8, 0)
	end)
end

function RoundManager.init()
	Remotes.ensure()
	RoundManager.setupCollisions()
	RoundManager.setupDash()
	task.wait(1)
	RoundManager.startRound()
end

return RoundManager
