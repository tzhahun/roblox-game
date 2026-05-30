-- Portal / teleporter support for player-ball characters.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PortalSupport = {}

local BALL_RADIUS = 4

local lastTeleport: { [Player]: number } = {}
local teleportLockUntil: { [Player]: number } = {}
local portalSources: { BasePart } = {}

local TELEPORT_COOLDOWN = 0.75
local TELEPORT_LOCK_TIME = 1.25

local KEYWORDS = { "portal", "teleport", "teleporter", "warp", "gate" }
local DEST_CHILD_NAMES = { "Destination", "Exit", "End", "Target", "TeleportTo", "Out" }

local function nameMatchesKeyword(name: string): boolean
	local lower = string.lower(name)
	for _, word in KEYWORDS do
		if string.find(lower, word, 1, true) then
			return true
		end
	end
	return false
end

local function namesMatch(a: string, b: string): boolean
	return string.lower(a) == string.lower(b)
end

local function isPortal1(part: BasePart): boolean
	return namesMatch(part.Name, GameConfig.PORTAL1_NAME)
		or (part.Parent ~= nil and namesMatch(part.Parent.Name, GameConfig.PORTAL1_NAME))
end

local function isPortal2(part: BasePart): boolean
	return namesMatch(part.Name, GameConfig.PORTAL2_NAME)
		or (part.Parent ~= nil and namesMatch(part.Parent.Name, GameConfig.PORTAL2_NAME))
end

local function isOneWayPortal(part: BasePart): boolean
	return part:GetAttribute("OneWay") == true or isPortal2(part)
end

local function isDestinationOnly(part: BasePart): boolean
	if part:GetAttribute("DestinationOnly") == true then
		return true
	end
	return isPortal1(part)
end

local function canBeDestination(part: BasePart): boolean
	return not isOneWayPortal(part)
end

local function canSendPlayers(part: BasePart): boolean
	return not isDestinationOnly(part)
end

function PortalSupport.isLocked(player: Player): boolean
	local untilTime = teleportLockUntil[player]
	if untilTime ~= nil and os.clock() < untilTime then
		return true
	end
	local attrLock = player:GetAttribute("PortalTeleportLock")
	return type(attrLock) == "number" and os.clock() < attrLock
end

local function resolveToBasePart(instance: Instance?): BasePart?
	if not instance then
		return nil
	end
	if instance:IsA("BasePart") then
		return instance
	end
	if instance:IsA("Model") then
		if instance.PrimaryPart and instance.PrimaryPart:IsA("BasePart") then
			return instance.PrimaryPart
		end
		return instance:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function findNamedPart(name: string): BasePart?
	local lower = string.lower(name)
	for _, descendant in workspace:GetDescendants() do
		if string.lower(descendant.Name) == lower then
			local part = resolveToBasePart(descendant)
			if part then
				return part
			end
		end
	end
	return nil
end

local function getPortalRoot(part: BasePart): Instance
	if part:GetAttribute("IsPortal") == true or nameMatchesKeyword(part.Name) then
		return part
	end
	local parent = part.Parent
	if parent and (parent:IsA("Model") or parent:IsA("Folder")) and nameMatchesKeyword(parent.Name) then
		return parent
	end
	return part
end

local function isPortalPart(part: BasePart): boolean
	if part:GetAttribute("IsPortal") == true then
		return true
	end
	if nameMatchesKeyword(part.Name) then
		return true
	end
	local parent = part.Parent
	if parent and nameMatchesKeyword(parent.Name) then
		return true
	end
	return false
end

local function tryDestination(part: Instance?): BasePart?
	local resolved = resolveToBasePart(part)
	if resolved and canBeDestination(resolved) then
		return resolved
	end
	return nil
end

local function findDestination(portalRoot: Instance): BasePart?
	-- Hard-coded game link: Portal2 (entrance) -> Portal1 (destination)
	if portalRoot:IsA("BasePart") and isPortal2(portalRoot) then
		local portal1 = findNamedPart(GameConfig.PORTAL1_NAME)
		if portal1 then
			return portal1
		end
	end
	if portalRoot:IsA("Model") and namesMatch(portalRoot.Name, GameConfig.PORTAL2_NAME) then
		local portal1 = findNamedPart(GameConfig.PORTAL1_NAME)
		if portal1 then
			return portal1
		end
	end

	for _, childName in DEST_CHILD_NAMES do
		local dest = portalRoot:FindFirstChild(childName, true)
		local valid = tryDestination(dest)
		if valid then
			return valid
		end
	end

	local destName = portalRoot:GetAttribute("TeleportTo")
	if type(destName) == "string" and destName ~= "" then
		local valid = tryDestination(findNamedPart(destName) or workspace:FindFirstChild(destName, true))
		if valid then
			return valid
		end
	end

	for _, desc in portalRoot:GetDescendants() do
		if desc:IsA("ObjectValue") and desc.Value then
			local valid = tryDestination(desc.Value)
			if valid then
				return valid
			end
		end
	end

	if portalRoot:IsA("BasePart") then
		local name = portalRoot.Name
		local pairNames = {
			name:gsub("A$", "B"),
			name:gsub("1$", "2"),
			name .. "B",
			name .. "2",
			name .. "_Out",
			name .. "Out",
		}
		for _, pairName in pairNames do
			if pairName ~= name then
				local valid = tryDestination(findNamedPart(pairName) or workspace:FindFirstChild(pairName, true))
				if valid then
					return valid
				end
			end
		end
	end

	return nil
end

local function applyPortal1Style(portal: BasePart)
	-- Portal1 = destination only; decoration stays visible.
	local inPortal1Model = portal.Parent ~= nil and namesMatch(portal.Parent.Name, GameConfig.PORTAL1_NAME)
	if inPortal1Model and portal.Name ~= "Trigger" then
		return
	end
	if not isPortal1(portal) and not inPortal1Model then
		return
	end
	if portal.Name ~= "Trigger" and not namesMatch(portal.Name, GameConfig.PORTAL1_NAME) then
		return
	end

	portal.Transparency = 1
	portal.CanCollide = false
	portal.CanTouch = false
	portal:SetAttribute("DestinationOnly", true)
	portal:SetAttribute("OneWay", nil)
	portal:SetAttribute("PortalNoCollide", true)
end

local function applyPortal2Style(portal: BasePart)
	-- Portal2 = entrance trigger only (invisible).
	local inPortal2Model = portal.Parent ~= nil and namesMatch(portal.Parent.Name, GameConfig.PORTAL2_NAME)
	if inPortal2Model and portal.Name ~= "Trigger" then
		return
	end
	if not isPortal2(portal) and not inPortal2Model then
		return
	end
	if portal.Name ~= "Trigger" and not namesMatch(portal.Name, GameConfig.PORTAL2_NAME) then
		return
	end

	portal.Transparency = 1
	portal.CanCollide = false
	portal.CanTouch = true
	portal.CastShadow = false
	portal:SetAttribute("OneWay", true)
	portal:SetAttribute("DestinationOnly", nil)
	portal:SetAttribute("PortalNoCollide", true)
end

local function preparePortalPart(portal: BasePart)
	applyPortal1Style(portal)
	applyPortal2Style(portal)

	portal.CanTouch = true

	if portal:GetAttribute("PortalNoCollide") == true then
		portal.CanCollide = false
		return
	end

	if portal:GetAttribute("DestinationOnly") == true then
		return
	end

	if portal.Transparency >= 1 and not isOneWayPortal(portal) then
		portal.CanCollide = true
	end
end

local function ballOverlapsPortal(ball: BasePart, portal: BasePart): boolean
	local relative = portal.CFrame:PointToObjectSpace(ball.Position)
	local half = portal.Size / 2 + Vector3.new(BALL_RADIUS, BALL_RADIUS, BALL_RADIUS)
	return math.abs(relative.X) <= half.X
		and math.abs(relative.Y) <= half.Y
		and math.abs(relative.Z) <= half.Z
end

local function teleportPlayer(player: Player, character: Model, portalPart: BasePart): boolean
	if not canSendPlayers(portalPart) then
		return false
	end

	local now = os.clock()
	if lastTeleport[player] and now - lastTeleport[player] < TELEPORT_COOLDOWN then
		return false
	end

	local portalRoot = getPortalRoot(portalPart)
	local destination = findDestination(portalRoot)
	if not destination then
		warn(`[PortalSupport] No destination for "{portalRoot:GetFullName()}".`)
		return false
	end

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local offset = Vector3.new(0, destination.Size.Y / 2 + BALL_RADIUS + 2, 0)
	local targetCFrame = destination.CFrame + offset

	lastTeleport[player] = now
	teleportLockUntil[player] = now + TELEPORT_LOCK_TIME
	player:SetAttribute("PortalTeleportLock", now + TELEPORT_LOCK_TIME)

	character:PivotTo(targetCFrame)

	local ball = character:FindFirstChild("PlayerBall")
	if ball and ball:IsA("BasePart") then
		ball.AssemblyLinearVelocity = Vector3.zero
		ball.AssemblyAngularVelocity = Vector3.zero
	end

	if humanoid then
		humanoid:MoveTo(destination.Position + offset)
	end

	print(`[PortalSupport] {player.Name}: {portalPart.Name} -> {destination:GetFullName()}`)
	return true
end

function PortalSupport.tryTeleport(player: Player, character: Model, touchedPart: BasePart): boolean
	if not isPortalPart(touchedPart) or not canSendPlayers(touchedPart) then
		return false
	end
	return teleportPlayer(player, character, touchedPart)
end

local function registerPortal(part: BasePart)
	if not isPortalPart(part) then
		return
	end
	preparePortalPart(part)

	-- Portal2 is landing-only; do not use it as a teleport source.
	if canSendPlayers(part) and not table.find(portalSources, part) then
		table.insert(portalSources, part)
	end
end

local function scan(root: Instance)
	for _, descendant in root:GetDescendants() do
		if descendant:IsA("BasePart") then
			registerPortal(descendant)
		end
	end
end

local function setupOverlapCheck()
	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			if PortalSupport.isLocked(player) then
				continue
			end

			local character = player.Character
			if not character then
				continue
			end

			local ball = character:FindFirstChild("PlayerBall")
			if not ball or not ball:IsA("BasePart") then
				continue
			end

			for _, portal in portalSources do
				if portal.Parent and ballOverlapsPortal(ball, portal) then
					if teleportPlayer(player, character, portal) then
						break
					end
				end
			end
		end
	end)
end

function PortalSupport.init()
	table.clear(portalSources)
	scan(workspace)

	task.delay(2, function()
		scan(workspace)

		local portal1 = findNamedPart(GameConfig.PORTAL1_NAME)
		local portal2 = findNamedPart(GameConfig.PORTAL2_NAME)
		if portal1 and portal2 then
			print(`[PortalSupport] Ready: {GameConfig.PORTAL2_NAME} -> {GameConfig.PORTAL1_NAME} (one-way).`)
		else
			warn(`[PortalSupport] Missing portal — Portal1: {portal1 ~= nil}, Portal2: {portal2 ~= nil}`)
		end
		print(`[PortalSupport] Active portal sources: {#portalSources}`)
	end)

	workspace.DescendantAdded:Connect(function(descendant)
		if descendant:IsA("BasePart") then
			task.defer(function()
				registerPortal(descendant)
			end)
		end
	end)

	setupOverlapCheck()
end

return PortalSupport
