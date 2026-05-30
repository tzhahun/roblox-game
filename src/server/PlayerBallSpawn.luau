-- Roll inside a translucent ball; bump others on your own map (no auto-built arena).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local Knockback = require(ReplicatedStorage.Shared.Knockback)
local Remotes = require(script.Parent.Remotes)
local PortalSupport = require(script.Parent.PortalSupport)
local PortalSystem = require(script.Parent.PortalSystem)

local PlayerBallSpawn = {}

local BALL_RADIUS = 4
local BALL_DIAMETER = BALL_RADIUS * 2
local BALL_TRANSPARENCY = 0.45

local alive: { [Player]: boolean } = {}
local lastBump: { [string]: number } = {}
local roundActive = false

type RecentMotion = {
	strafeDir: Vector3?,
	strafeUntil: number,
	bumpDir: Vector3?,
	bumpUntil: number,
}

local recentMotion: { [Player]: RecentMotion } = {}

local function flatUnit(vector: Vector3): Vector3?
	local flat = Vector3.new(vector.X, 0, vector.Z)
	if flat.Magnitude < 0.05 then
		return nil
	end
	return flat.Unit
end

local function isOppositeDirection(moveDir: Vector3, priorDir: Vector3?): boolean
	if not priorDir then
		return false
	end
	return moveDir:Dot(priorDir) < -0.25
end

local function rememberStrafe(player: Player, direction: Vector3)
	local recent = recentMotion[player] or {}
	recent.strafeDir = direction
	recent.strafeUntil = os.clock() + GameConfig.BALL_OPPOSITE_WINDOW
	recentMotion[player] = recent
end

local function rememberBump(player: Player, impulse: Vector3)
	local bumpDir = flatUnit(impulse)
	if not bumpDir then
		return
	end
	local recent = recentMotion[player] or {}
	recent.bumpDir = bumpDir
	recent.bumpUntil = os.clock() + GameConfig.BALL_OPPOSITE_WINDOW
	recentMotion[player] = recent
end

local function getTargetSpeed(player: Player, direction: Vector3, lookFlat: Vector3): number
	if lookFlat.Magnitude > 0.05 and direction:Dot(lookFlat.Unit) < -0.25 then
		return GameConfig.BALL_BACK_SPEED
	end

	local recent = recentMotion[player]
	if not recent then
		return GameConfig.BALL_ROLL_SPEED
	end

	local now = os.clock()
	if recent.strafeDir and now < recent.strafeUntil and isOppositeDirection(direction, recent.strafeDir) then
		return GameConfig.BALL_BACK_SPEED
	end
	if recent.bumpDir and now < recent.bumpUntil and isOppositeDirection(direction, recent.bumpDir) then
		return GameConfig.BALL_BACK_SPEED
	end

	return GameConfig.BALL_ROLL_SPEED
end

local function removeGeneratedArena()
	local arena = workspace:FindFirstChild("Arena")
	if arena then
		arena:Destroy()
	end
end

local function watchForArenaRespawn()
	workspace.ChildAdded:Connect(function(child)
		if child.Name == "Arena" then
			task.defer(function()
				child:Destroy()
			end)
		end
	end)
end

local function platformSurfaceY(part: BasePart): number
	return part.Position.Y + part.Size.Y / 2
end

local function getFallY(): number
	-- Use the lowest play surface so teleport destinations (e.g. Portal2) are not treated as a fall.
	local lowestSurface = math.huge

	local function consider(part: BasePart)
		lowestSurface = math.min(lowestSurface, platformSurfaceY(part))
	end

	local spawn = workspace:FindFirstChildWhichIsA("SpawnLocation", true)
	if spawn then
		consider(spawn)
	end

	local baseplate = workspace:FindFirstChild("Baseplate")
	if baseplate and baseplate:IsA("BasePart") then
		consider(baseplate)
	end

	local starting = workspace:FindFirstChild("StartingPlatform", true)
	if starting and starting:IsA("BasePart") then
		consider(starting)
	elseif starting and starting:IsA("Model") then
		local part = starting.PrimaryPart or starting:FindFirstChildWhichIsA("BasePart", true)
		if part then
			consider(part)
		end
	end

	local abc = workspace:FindFirstChild("abc", true)
	if abc and abc:IsA("BasePart") then
		consider(abc)
	elseif abc and abc:IsA("Model") then
		local part = abc.PrimaryPart or abc:FindFirstChildWhichIsA("BasePart", true)
		if part then
			consider(part)
		end
	end

	local portals = workspace:FindFirstChild("GamePortals")
	if portals then
		for _, portalModel in portals:GetChildren() do
			local platform = portalModel:FindFirstChild("Platform")
			if platform and platform:IsA("BasePart") then
				consider(platform)
			else
				local trigger = portalModel:FindFirstChild("Trigger", true)
				if trigger and trigger:IsA("BasePart") then
					consider(trigger)
				end
			end
		end
	end

	if lowestSurface == math.huge then
		return -50
	end

	return lowestSurface - GameConfig.FALL_DISTANCE
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

local function getBall(character: Model?): BasePart?
	if not character then
		return nil
	end
	local ball = character:FindFirstChild("PlayerBall")
	if ball and ball:IsA("BasePart") then
		return ball
	end
	return nil
end

local function getPlayerFromBall(ball: BasePart): Player?
	local character = ball.Parent
	if not character or not character:IsA("Model") then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function isMovementLocked(player: Player): boolean
	if PortalSupport.isLocked(player) then
		return true
	end
	local lockUntil = player:GetAttribute("PortalTeleportLock")
	return type(lockUntil) == "number" and os.clock() < lockUntil
end

function PlayerBallSpawn.isPlayerAlive(player: Player): boolean
	return alive[player] == true
end

function PlayerBallSpawn.eliminate(player: Player)
	if not alive[player] then
		return
	end
	alive[player] = false
	recentMotion[player] = nil

	local character = player.Character
	if character then
		character:Destroy()
	end

	if roundActive and countAlive() <= 1 then
		task.defer(PlayerBallSpawn.endRound)
	else
		task.delay(GameConfig.BALL_RESPAWN_DELAY, function()
			if not roundActive or not player.Parent then
				return
			end
			alive[player] = true
			player:LoadCharacter()
		end)
	end
end

local function hideOverheadText(character: Model, humanoid: Humanoid)
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.NameDisplayDistance = 0
	humanoid.NameOcclusion = Enum.NameOcclusion.OccludeAll

	for _, gui in character:GetDescendants() do
		if gui:IsA("BillboardGui") then
			gui.Enabled = false
		end
	end
end

local function setupPlayerBall(player: Player, character: Model)
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart
	local humanoid = character:WaitForChild("Humanoid") :: Humanoid

	local existing = character:FindFirstChild("PlayerBall")
	if existing then
		existing:Destroy()
	end

	local ball = Instance.new("Part")
	ball.Name = "PlayerBall"
	ball.Shape = Enum.PartType.Ball
	ball.Size = Vector3.new(BALL_DIAMETER, BALL_DIAMETER, BALL_DIAMETER)
	ball.Material = Enum.Material.Glass
	ball.Color = Color3.fromRGB(255, 255, 255)
	ball.Transparency = BALL_TRANSPARENCY
	ball.Anchored = false
	ball.CanCollide = true
	ball.Massless = false
	ball.CustomPhysicalProperties = PhysicalProperties.new(0.35, GameConfig.BALL_ICE_FRICTION, 0.05, 1, 1)
	ball:SetAttribute("IsPlayerBall", true)
	ball.Parent = character

	ball.CFrame = humanoidRootPart.CFrame

	local weld = Instance.new("WeldConstraint")
	weld.Part0 = ball
	weld.Part1 = humanoidRootPart
	weld.Parent = ball

	for _, part in character:GetDescendants() do
		if part:IsA("BasePart") and part ~= ball then
			part.CanCollide = false
			if part ~= humanoidRootPart then
				part.Massless = true
			end
		end
	end

	humanoid.WalkSpeed = 0
	humanoid.JumpPower = 50
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true
	humanoid.HipHeight = math.max(humanoid.HipHeight, BALL_DIAMETER * 0.35)
	hideOverheadText(character, humanoid)

	humanoid:GetPropertyChangedSignal("Jump"):Connect(function()
		if humanoid.Jump and alive[player] then
			local velocity = ball.AssemblyLinearVelocity
			ball.AssemblyLinearVelocity = Vector3.new(velocity.X, GameConfig.BALL_JUMP_IMPULSE, velocity.Z)
		end
	end)

	ball.Touched:Connect(function(other)
		if not other:IsA("BasePart") then
			return
		end
		if not alive[player] then
			return
		end

		if PortalSupport.tryTeleport(player, character, other) then
			return
		end

		if other.Name ~= "PlayerBall" then
			return
		end

		local otherPlayer = getPlayerFromBall(other)
		if not otherPlayer or not alive[otherPlayer] or otherPlayer == player then
			return
		end

		local key = ball:GetFullName() .. "|" .. other:GetFullName()
		local bumpNow = os.clock()
		local last = lastBump[key]
		if last and bumpNow - last < GameConfig.BUMP_COOLDOWN then
			return
		end

		local impulseA, impulseB = Knockback.computeBump(
			ball.AssemblyLinearVelocity,
			other.AssemblyLinearVelocity,
			ball.Position,
			other.Position
		)
		if not impulseA or not impulseB then
			return
		end

		lastBump[key] = bumpNow
		ball.AssemblyLinearVelocity += impulseA
		other.AssemblyLinearVelocity += impulseB

		rememberBump(player, impulseA)
		rememberBump(otherPlayer, impulseB)
	end)
end

function PlayerBallSpawn.startRound()
	roundActive = true
	removeGeneratedArena()

	local players = Players:GetPlayers()
	if #players < GameConfig.MIN_PLAYERS_TO_START then
		return
	end

	for _, player in players do
		alive[player] = true
		player:LoadCharacter()
	end
end

function PlayerBallSpawn.endRound()
	if not roundActive then
		return
	end
	roundActive = false

	task.wait(GameConfig.ROUND_INTERMISSION)
	PlayerBallSpawn.startRound()
end

local function setupRollPhysics()
	RunService.Heartbeat:Connect(function()
		if not roundActive then
			return
		end

		for _, player in Players:GetPlayers() do
			if not alive[player] then
				continue
			end

			if isMovementLocked(player) then
				continue
			end

			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local ball = getBall(character)
			if not humanoid or not ball then
				continue
			end

			local move = humanoid.MoveDirection
			local velocity = ball.AssemblyLinearVelocity
			local horizontal = Vector3.new(velocity.X, 0, velocity.Z)

			if horizontal.Magnitude > 5 then
				local rightFlat = flatUnit(ball.CFrame.RightVector)
				if rightFlat then
					local lateral = horizontal:Dot(rightFlat)
					if math.abs(lateral) > horizontal.Magnitude * 0.5 then
						rememberStrafe(player, rightFlat * (if lateral > 0 then 1 else -1))
					end
				end
			end

			if move.Magnitude > 0.05 then
				local flatMove = Vector3.new(move.X, 0, move.Z)
				if flatMove.Magnitude > 0.05 then
					local direction = flatMove.Unit
					local look = ball.CFrame.LookVector
					local lookFlat = Vector3.new(look.X, 0, look.Z)

					local rightFlat = flatUnit(ball.CFrame.RightVector)
					if rightFlat then
						local strafeAmount = direction:Dot(rightFlat)
						if math.abs(strafeAmount) > 0.55 then
							rememberStrafe(player, rightFlat * (if strafeAmount > 0 then 1 else -1))
						end
					end

					local speed = getTargetSpeed(player, direction, lookFlat)
					local target = direction * speed
					local blended = horizontal:Lerp(target, GameConfig.BALL_ROLL_ACCEL)
					ball.AssemblyLinearVelocity = Vector3.new(blended.X, velocity.Y, blended.Z)

					local rollRate = blended.Magnitude / BALL_RADIUS
					ball.AssemblyAngularVelocity = Vector3.new(-direction.Z, 0, direction.X) * rollRate
				end
			else
				local sliding = horizontal * GameConfig.BALL_GLIDE_DRAG
				if sliding.Magnitude < 0.35 then
					sliding = Vector3.zero
				end
				ball.AssemblyLinearVelocity = Vector3.new(sliding.X, velocity.Y, sliding.Z)
				ball.AssemblyAngularVelocity = ball.AssemblyAngularVelocity * 0.99
			end
		end
	end)
end

local function setupFallCheck()
	RunService.Heartbeat:Connect(function()
		if not roundActive then
			return
		end

		local fallY = getFallY()

		for _, player in Players:GetPlayers() do
			if not alive[player] then
				continue
			end

			if isMovementLocked(player) then
				continue
			end

			local ball = getBall(player.Character)
			if not ball then
				continue
			end

			if ball.Position.Y < fallY then
				PlayerBallSpawn.eliminate(player)
			end
		end
	end)
end

local function setupDash()
	Remotes.Dash.OnServerEvent:Connect(function(player)
		if not roundActive or not alive[player] then
			return
		end

		local ball = getBall(player.Character)
		if not ball then
			return
		end

		local lastDash = player:GetAttribute("LastDash") or 0
		if os.clock() - lastDash < GameConfig.DASH_COOLDOWN then
			return
		end
		player:SetAttribute("LastDash", os.clock())

		local direction = ball.AssemblyLinearVelocity
		if direction.Magnitude < 2 then
			direction = ball.CFrame.LookVector
		end
		direction = Vector3.new(direction.X, 0, direction.Z)
		if direction.Magnitude < 0.1 then
			direction = Vector3.new(0, 0, -1)
		else
			direction = direction.Unit
		end

		ball.AssemblyLinearVelocity += direction * GameConfig.DASH_POWER + Vector3.new(0, 8, 0)
	end)
end

function PlayerBallSpawn.init()
	Remotes.ensure()
	PortalSystem.start()
	removeGeneratedArena()
	watchForArenaRespawn()

	task.spawn(function()
		while true do
			removeGeneratedArena()
			task.wait(2)
		end
	end)

	Players.CharacterAutoLoads = false

	local function bindPlayer(player: Player)
		alive[player] = false

		player.CharacterAdded:Connect(function(character)
			task.defer(function()
				setupPlayerBall(player, character)
			end)
		end)
	end

	Players.PlayerAdded:Connect(function(player)
		bindPlayer(player)
		if roundActive then
			task.wait(0.5)
			if roundActive then
				alive[player] = true
				player:LoadCharacter()
			end
		end
	end)

	Players.PlayerRemoving:Connect(function(player)
		alive[player] = nil
		recentMotion[player] = nil
		if roundActive and countAlive() <= 1 then
			task.defer(PlayerBallSpawn.endRound)
		end
	end)

	for _, player in Players:GetPlayers() do
		bindPlayer(player)
	end

	setupRollPhysics()
	setupFallCheck()
	setupDash()

	task.wait(1)
	PlayerBallSpawn.startRound()

	print("[PlayerBall] Ready — roll and bump on your map (no generated arena).")
end

return PlayerBallSpawn
