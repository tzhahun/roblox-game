-- Portal2 (entrance trigger) -> Portal1 (destination). Works with Rojo-synced world/GamePortals.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local PortalSystem = {}

local PORTAL1 = GameConfig.PORTAL1_NAME or "Portal1"
local PORTAL2 = GameConfig.PORTAL2_NAME or "Portal2"
local PORTAL1_ANCHOR = GameConfig.PORTAL1_ANCHOR or "abc"
local PORTAL2_ANCHOR = GameConfig.PORTAL2_ANCHOR or "StartingPlatform"

local BLUE = Color3.fromRGB(64, 168, 255)
local BLUE_BRIGHT = Color3.fromRGB(130, 210, 255)
local BLUE_DEEP = Color3.fromRGB(25, 95, 200)

-- Portal1 entrance (visible cyan / white — different from blue exit)
local CYAN = Color3.fromRGB(120, 220, 255)
local CYAN_BRIGHT = Color3.fromRGB(210, 245, 255)
local CYAN_DEEP = Color3.fromRGB(70, 150, 210)
local ENTRANCE_FLOOR = Color3.fromRGB(45, 58, 72)

local BALL_RADIUS = 4
local TELEPORT_LOCK_SECONDS = 4

local portal1: BasePart? = nil
local portal2: BasePart? = nil
local lastTeleport: { [Player]: number } = {}
local started = false

local function findTrigger(folder: Instance?, modelName: string): BasePart?
	if not folder then
		return nil
	end
	local model = folder:FindFirstChild(modelName)
	if not model then
		return nil
	end
	local trigger = model:FindFirstChild("Trigger", true)
	if trigger and trigger:IsA("BasePart") then
		return trigger
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function addLight(parent: Instance, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Parent = parent
end

local function addParticles(parent: BasePart, color: Color3, rate: number?)
	local attachment = Instance.new("Attachment")
	attachment.Parent = parent
	local particles = Instance.new("ParticleEmitter")
	particles.Color = ColorSequence.new(color)
	particles.LightEmission = 1
	particles.Size = NumberSequence.new(0.35, 0)
	particles.Transparency = NumberSequence.new(0.15, 1)
	particles.Lifetime = NumberRange.new(0.6, 1.1)
	particles.Rate = rate or 24
	particles.Speed = NumberRange.new(2, 5)
	particles.SpreadAngle = Vector2.new(180, 180)
	particles.Parent = attachment
end

local ENTRANCE_DECO_NAMES = {
	"EntrancePad",
	"EntranceRing",
	"EntranceCore",
	"EntranceArch",
	"Sign",
}

local function clearEntranceVisuals(model: Model)
	for _, name in ENTRANCE_DECO_NAMES do
		local child = model:FindFirstChild(name)
		if child then
			child:Destroy()
		end
	end
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and string.find(child.Name, "EntrancePillar", 1, true) == 1 then
			child:Destroy()
		end
	end
end

local function entranceVisualsAreVisible(model: Model): boolean
	local ring = model:FindFirstChild("EntranceRing")
	return ring ~= nil and ring:IsA("BasePart") and ring.Transparency < 1
end

local function styleEntranceDeco(model: Model)
	for _, name in ENTRANCE_DECO_NAMES do
		local part = model:FindFirstChild(name)
		if part and part:IsA("BasePart") then
			part.CanCollide = false
			part.Anchored = true
			if part.Name == "EntranceCore" then
				part.Material = Enum.Material.Glass
				part.Color = CYAN_BRIGHT
				part.Transparency = 0.4
			elseif part.Name == "Sign" then
				part.Material = Enum.Material.Neon
				part.Color = Color3.fromRGB(255, 255, 255)
			elseif part.Name == "EntrancePad" or part.Name == "EntranceRing" or part.Name == "EntranceArch" then
				part.Material = Enum.Material.Neon
			end
		end
	end
	for _, child in model:GetChildren() do
		if child:IsA("BasePart") and string.find(child.Name, "EntrancePillar", 1, true) == 1 then
			child.Material = Enum.Material.Neon
			child.Color = CYAN_DEEP
			child.CanCollide = false
			child.Anchored = true
		end
	end

	local core = model:FindFirstChild("EntranceCore")
	if core and core:IsA("BasePart") and not core:FindFirstChildOfClass("PointLight") then
		addLight(core, CYAN_BRIGHT, 2.2, 20)
	end

	local ring = model:FindFirstChild("EntranceRing")
	if ring and ring:IsA("BasePart") and not ring:FindFirstChildOfClass("PointLight") then
		addLight(ring, CYAN, 1.6, 16)
	end

	if core and core:IsA("BasePart") and not core:FindFirstChildOfClass("ParticleEmitter") then
		addParticles(core, CYAN_BRIGHT, 32)
	end

	local sign = model:FindFirstChild("Sign")
	if sign and sign:IsA("BasePart") and not sign:FindFirstChildOfClass("SurfaceGui") then
		local signGui = Instance.new("SurfaceGui")
		signGui.Face = Enum.NormalId.Front
		signGui.Parent = sign
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "ENTER"
		label.TextColor3 = CYAN_BRIGHT
		label.TextScaled = true
		label.Font = Enum.Font.GothamBold
		label.Parent = signGui
	end
end

local function ensureEntranceVisuals(model: Model, trigger: BasePart)
	if entranceVisualsAreVisible(model) then
		styleEntranceDeco(model)
		return
	end

	clearEntranceVisuals(model)

	local platform = model:FindFirstChild("Platform")
	if not platform or not platform:IsA("BasePart") then
		platform = Instance.new("Part")
		platform.Name = "Platform"
		platform.Size = Vector3.new(36, 1.2, 36)
		platform.CFrame = trigger.CFrame * CFrame.new(0, -6.5, 0)
		platform.Anchored = true
		platform.Material = Enum.Material.SmoothPlastic
		platform.Color = ENTRANCE_FLOOR
		platform.CanCollide = false
		platform.Parent = model
	end

	local platY = platform.Size.Y / 2
	local base = platform.CFrame * CFrame.new(0, platY + 0.2, 0)

	local pad = Instance.new("Part")
	pad.Name = "EntrancePad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.5, 16, 16)
	pad.CFrame = base * CFrame.Angles(0, 0, math.rad(90))
	pad.Anchored = true
	pad.Material = Enum.Material.Neon
	pad.Color = CYAN
	pad.CanCollide = false
	pad.Parent = model

	local ring = Instance.new("Part")
	ring.Name = "EntranceRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.45, 18, 18)
	ring.CFrame = base * CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.Material = Enum.Material.Neon
	ring.Color = CYAN_BRIGHT
	ring.CanCollide = false
	ring.Parent = model

	local core = Instance.new("Part")
	core.Name = "EntranceCore"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(7, 7, 7)
	core.CFrame = base * CFrame.new(0, 2, 0)
	core.Anchored = true
	core.Material = Enum.Material.Glass
	core.Color = CYAN_BRIGHT
	core.Transparency = 0.4
	core.CanCollide = false
	core.Parent = model

	for i = 0, 3 do
		local angle = math.rad(i * 90 + 45)
		local pillar = Instance.new("Part")
		pillar.Name = `EntrancePillar{i}`
		pillar.Size = Vector3.new(1, 7, 1)
		pillar.CFrame = base * CFrame.new(math.cos(angle) * 8, 3.5, math.sin(angle) * 8)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Neon
		pillar.Color = CYAN_DEEP
		pillar.CanCollide = false
		pillar.Parent = model
	end

	local arch = Instance.new("Part")
	arch.Name = "EntranceArch"
	arch.Size = Vector3.new(17, 0.8, 1)
	arch.CFrame = base * CFrame.new(0, 7.2, 0)
	arch.Anchored = true
	arch.Material = Enum.Material.Neon
	arch.Color = CYAN_BRIGHT
	arch.CanCollide = false
	arch.Parent = model

	local sign = Instance.new("Part")
	sign.Name = "Sign"
	sign.Size = Vector3.new(8, 2.5, 0.3)
	sign.CFrame = base * CFrame.new(0, 8.8, -1.2)
	sign.Anchored = true
	sign.Material = Enum.Material.Neon
	sign.Color = Color3.fromRGB(255, 255, 255)
	sign.CanCollide = false
	sign.Parent = model

	local signGui = Instance.new("SurfaceGui")
	signGui.Face = Enum.NormalId.Front
	signGui.Parent = sign
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.Text = "ENTER"
	label.TextColor3 = CYAN_BRIGHT
	label.TextScaled = true
	label.Font = Enum.Font.GothamBold
	label.Parent = signGui

	addLight(core, CYAN_BRIGHT, 2.2, 20)
	addLight(ring, CYAN, 1.6, 16)
	addParticles(core, CYAN_BRIGHT, 32)
end

local function stylePortal1(trigger: BasePart)
	local model = trigger.Parent
	if not model or not model:IsA("Model") then
		return
	end

	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.CanTouch = false
	trigger.Size = Vector3.new(18, 12, 18)
	trigger:SetAttribute("OneWay", nil)
	trigger:SetAttribute("DestinationOnly", true)

	local platform = model:FindFirstChild("Platform")
	if platform and platform:IsA("BasePart") then
		platform.Material = Enum.Material.SmoothPlastic
		platform.Color = ENTRANCE_FLOOR
		platform.Anchored = true
		platform.CanCollide = true
	end

	ensureEntranceVisuals(model, trigger)
	styleEntranceDeco(model)
	model.PrimaryPart = trigger
end

local function ensureBlueVisuals(model: Model, padCFrame: CFrame)
	if model:FindFirstChild("OuterRing") then
		return
	end

	local platform = model:FindFirstChild("Platform")
	local platY = if platform and platform:IsA("BasePart") then platform.Size.Y / 2 else 0.75
	local base = padCFrame * CFrame.new(0, platY + 0.2, 0)

	local pad = Instance.new("Part")
	pad.Name = "Pad"
	pad.Shape = Enum.PartType.Cylinder
	pad.Size = Vector3.new(0.6, 18, 18)
	pad.CFrame = base * CFrame.Angles(0, 0, math.rad(90))
	pad.Anchored = true
	pad.Material = Enum.Material.Neon
	pad.Color = BLUE
	pad.CanCollide = false
	pad.Parent = model

	local ring = Instance.new("Part")
	ring.Name = "OuterRing"
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.5, 20, 20)
	ring.CFrame = base * CFrame.new(0, 1.1, 0) * CFrame.Angles(0, 0, math.rad(90))
	ring.Anchored = true
	ring.Material = Enum.Material.Neon
	ring.Color = BLUE_BRIGHT
	ring.CanCollide = false
	ring.Parent = model

	local core = Instance.new("Part")
	core.Name = "Core"
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(9, 9, 9)
	core.CFrame = base * CFrame.new(0, 2.2, 0)
	core.Anchored = true
	core.Material = Enum.Material.Glass
	core.Color = BLUE_BRIGHT
	core.Transparency = 0.55
	core.CanCollide = false
	core.Parent = model

	for i = 0, 3 do
		local angle = math.rad(i * 90)
		local pillar = Instance.new("Part")
		pillar.Name = `Pillar{i}`
		pillar.Size = Vector3.new(1.2, 8, 1.2)
		pillar.CFrame = base * CFrame.new(math.cos(angle) * 9, 4, math.sin(angle) * 9)
		pillar.Anchored = true
		pillar.Material = Enum.Material.Neon
		pillar.Color = BLUE_DEEP
		pillar.CanCollide = false
		pillar.Parent = model
	end

	local arch = Instance.new("Part")
	arch.Name = "Arch"
	arch.Size = Vector3.new(20, 1, 1.2)
	arch.CFrame = base * CFrame.new(0, 8.2, 0)
	arch.Anchored = true
	arch.Material = Enum.Material.Neon
	arch.Color = BLUE
	arch.CanCollide = false
	arch.Parent = model

	addLight(core, BLUE_BRIGHT, 2.5, 22)
	addLight(ring, BLUE, 1.8, 18)
	addParticles(core, BLUE_BRIGHT)
end

local function stylePortal2(trigger: BasePart)
	local model = trigger.Parent
	if not model or not model:IsA("Model") then
		return
	end

	trigger.Transparency = 1
	trigger.CanCollide = false
	trigger.CanTouch = true
	trigger.CastShadow = false
	trigger.Size = Vector3.new(18, 14, 18)
	trigger:SetAttribute("OneWay", true)
	trigger:SetAttribute("DestinationOnly", nil)

	local platform = model:FindFirstChild("Platform")
	if platform and platform:IsA("BasePart") then
		platform.Material = Enum.Material.SmoothPlastic
		platform.Color = Color3.fromRGB(28, 48, 78)
		platform.Anchored = true
	end

	ensureBlueVisuals(model, trigger.CFrame)
	model.PrimaryPart = trigger
end

local function findAnchorPart(anchorName: string): BasePart?
	local found = workspace:FindFirstChild(anchorName, true)
	if not found then
		return nil
	end
	if found:IsA("BasePart") then
		return found
	end
	if found:IsA("Model") then
		local primary = found.PrimaryPart
		if primary and primary:IsA("BasePart") then
			return primary
		end
		return found:FindFirstChildWhichIsA("BasePart", true)
	end
	return nil
end

local function getPortalPivotPart(model: Model): BasePart?
	local platform = model:FindFirstChild("Platform")
	if platform and platform:IsA("BasePart") then
		return platform
	end
	local trigger = model:FindFirstChild("Trigger")
	if trigger and trigger:IsA("BasePart") then
		return trigger
	end
	return model:FindFirstChildWhichIsA("BasePart", true)
end

local function alignPortalModelToAnchor(model: Model, anchorName: string): boolean
	local pivot = getPortalPivotPart(model)
	if not pivot then
		return false
	end

	local anchorPart = findAnchorPart(anchorName)
	if not anchorPart then
		warn(`[PortalSystem] Map part "{anchorName}" not found — {model.Name} left at current position.`)
		return false
	end

	local anchorTop = anchorPart.Size.Y / 2
	local pivotHalf = pivot.Size.Y / 2
	local targetPivotCF = anchorPart.CFrame * CFrame.new(0, anchorTop + pivotHalf, 0)
	local delta = targetPivotCF * pivot.CFrame:Inverse()

	for _, desc in model:GetDescendants() do
		if desc:IsA("BasePart") then
			desc.CFrame = delta * desc.CFrame
		end
	end

	return true
end

local function alignPortalsToMap()
	local folder = workspace:FindFirstChild("GamePortals")
	if not folder then
		return
	end

	local model1 = folder:FindFirstChild(PORTAL1)
	if model1 and model1:IsA("Model") then
		alignPortalModelToAnchor(model1, PORTAL1_ANCHOR)
	end

	local model2 = folder:FindFirstChild(PORTAL2)
	if model2 and model2:IsA("Model") then
		alignPortalModelToAnchor(model2, PORTAL2_ANCHOR)
	end
end

local function resolvePortals()
	local folder = workspace:FindFirstChild("GamePortals")
	portal1 = findTrigger(folder, PORTAL1)
	portal2 = findTrigger(folder, PORTAL2)

	if not portal1 or not portal2 then
		warn(`[PortalSystem] Missing portals in Workspace.GamePortals — Portal1: {portal1 ~= nil}, Portal2: {portal2 ~= nil}. Add them via the world/GamePortals models (Rojo).`)
	end

	alignPortalsToMap()

	if portal1 then
		stylePortal1(portal1)
	end
	if portal2 then
		stylePortal2(portal2)
	end
end

local function getCheckPart(player: Player): BasePart?
	local character = player.Character
	if not character then
		return nil
	end
	local ball = character:FindFirstChild("PlayerBall")
	if ball and ball:IsA("BasePart") then
		return ball
	end
	return character:FindFirstChild("HumanoidRootPart") :: BasePart?
end

local function getLandingCFrame(destination: BasePart): CFrame
	local model = destination.Parent
	if model and model:IsA("Model") then
		local platform = model:FindFirstChild("Platform")
		if platform and platform:IsA("BasePart") then
			local topY = platform.Position.Y + platform.Size.Y / 2
			return CFrame.new(platform.Position.X, topY + BALL_RADIUS, platform.Position.Z)
		end
	end

	local lift = destination.Size.Y / 2 + BALL_RADIUS + 1
	return CFrame.new(destination.Position + Vector3.new(0, lift, 0))
end

local function isInsideZone(part: BasePart, zone: BasePart): boolean
	local relative = zone.CFrame:PointToObjectSpace(part.Position)
	local half = zone.Size / 2 + Vector3.new(2, 4, 2)
	return math.abs(relative.X) <= half.X
		and math.abs(relative.Y) <= half.Y
		and math.abs(relative.Z) <= half.Z
end

local function tryTeleport(player: Player)
	if not portal1 or not portal2 then
		return
	end

	local now = os.clock()
	if lastTeleport[player] and now - lastTeleport[player] < 1 then
		return
	end

	local checkPart = getCheckPart(player)
	local character = player.Character
	if not checkPart or not character then
		return
	end

	if not isInsideZone(checkPart, portal2) then
		return
	end

	lastTeleport[player] = now
	player:SetAttribute("PortalTeleportLock", now + TELEPORT_LOCK_SECONDS)

	local landing = getLandingCFrame(portal1)
	character:PivotTo(landing)
	checkPart.AssemblyLinearVelocity = Vector3.zero
	checkPart.AssemblyAngularVelocity = Vector3.zero

	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid:MoveTo(landing.Position)
	end

	print(`[PortalSystem] {player.Name} teleported to {PORTAL1}.`)
end

function PortalSystem.start()
	if started then
		return
	end
	started = true

	resolvePortals()

	if portal1 and portal2 then
		print(`[PortalSystem] Ready: {PORTAL2} on {PORTAL2_ANCHOR} (enter) -> {PORTAL1} on {PORTAL1_ANCHOR} (exit)`)
	else
		warn("[PortalSystem] Portals missing — check Output.")
	end

	RunService.Heartbeat:Connect(function()
		for _, player in Players:GetPlayers() do
			tryTeleport(player)
		end
	end)
end

return PortalSystem
