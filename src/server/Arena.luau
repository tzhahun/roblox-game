local GameConfig = require(game:GetService("ReplicatedStorage").Shared.GameConfig)

local Arena = {}
local built = false

function Arena.ensure()
	if built then
		return workspace:FindFirstChild("Arena")
	end

	local existing = workspace:FindFirstChild("Arena")
	if existing then
		built = true
		return existing
	end

	local arena = Instance.new("Folder")
	arena.Name = "Arena"
	arena.Parent = workspace

	local platform = Instance.new("Part")
	platform.Name = "Platform"
	platform.Anchored = true
	platform.Size = GameConfig.PLATFORM_SIZE
	platform.Position = GameConfig.ARENA_CENTER
	platform.Material = Enum.Material.SmoothPlastic
	platform.Color = Color3.fromRGB(70, 130, 180)
	platform.TopSurface = Enum.SurfaceType.Smooth
	platform.BottomSurface = Enum.SurfaceType.Smooth
	platform.Parent = arena

	local rim = Instance.new("Part")
	rim.Name = "Rim"
	rim.Anchored = true
	rim.Size = Vector3.new(GameConfig.PLATFORM_SIZE.X + 2, 0.5, GameConfig.PLATFORM_SIZE.Z + 2)
	rim.Position = GameConfig.ARENA_CENTER + Vector3.new(0, GameConfig.PLATFORM_SIZE.Y / 2 + 0.25, 0)
	rim.Material = Enum.Material.Neon
	rim.Color = Color3.fromRGB(255, 200, 80)
	rim.CanCollide = false
	rim.Transparency = 0.35
	rim.Parent = arena

	local spawn = Instance.new("Part")
	spawn.Name = "SpawnMarker"
	spawn.Anchored = true
	spawn.CanCollide = false
	spawn.Transparency = 1
	spawn.Size = Vector3.new(1, 1, 1)
	spawn.Position = GameConfig.ARENA_CENTER + Vector3.new(0, GameConfig.PLATFORM_SIZE.Y / 2 + 3, 0)
	spawn.Parent = arena

	built = true
	return arena
end

function Arena.getSpawnCFrame(slot: number, total: number): CFrame
	local angle = (slot / math.max(total, 1)) * math.pi * 2
	local offset = Vector3.new(math.cos(angle) * GameConfig.SPAWN_RADIUS, 0, math.sin(angle) * GameConfig.SPAWN_RADIUS)
	local center = GameConfig.ARENA_CENTER + Vector3.new(0, GameConfig.PLATFORM_SIZE.Y / 2 + GameConfig.ORB_SIZE.Y / 2 + 1, 0)
	return CFrame.new(center + offset)
end

function Arena.getFallY(): number
	return GameConfig.ARENA_CENTER.Y - GameConfig.PLATFORM_SIZE.Y / 2 - GameConfig.FALL_DISTANCE
end

return Arena
