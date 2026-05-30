local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local OrbFactory = {}

local PLAYER_COLORS = {
	Color3.fromRGB(255, 90, 90),
	Color3.fromRGB(90, 160, 255),
	Color3.fromRGB(90, 255, 140),
	Color3.fromRGB(255, 220, 90),
	Color3.fromRGB(200, 90, 255),
	Color3.fromRGB(90, 255, 255),
}

local function pickColor(player: Player): Color3
	local index = ((player.UserId % #PLAYER_COLORS) + 1)
	return PLAYER_COLORS[index]
end

function OrbFactory.create(player: Player): Model
	local model = Instance.new("Model")
	model.Name = player.Name

	local orb = Instance.new("Part")
	orb.Name = "HumanoidRootPart"
	orb.Shape = Enum.PartType.Ball
	orb.Size = GameConfig.ORB_SIZE
	orb.Material = Enum.Material.Neon
	orb.Color = pickColor(player)
	orb.CanCollide = true
	orb.Massless = false
	orb.CustomPhysicalProperties = PhysicalProperties.new(
		GameConfig.ORB_DENSITY,
		GameConfig.ORB_FRICTION,
		GameConfig.ORB_ELASTICITY,
		1,
		1
	)
	orb.Parent = model

	local humanoid = Instance.new("Humanoid")
	humanoid.Name = "Humanoid"
	humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	humanoid.WalkSpeed = 26
	humanoid.JumpPower = 52
	humanoid.MaxHealth = 100
	humanoid.Health = 100
	humanoid.BreakJointsOnDeath = false
	humanoid.Parent = model

	model.PrimaryPart = orb
	model:SetAttribute("IsOrb", true)
	model:SetAttribute("PlayerUserId", player.UserId)

	return model
end

function OrbFactory.isOrbModel(model: Model?): boolean
	return model ~= nil and model:GetAttribute("IsOrb") == true
end

function OrbFactory.getOrbFromPart(part: BasePart?): Model?
	if not part then
		return nil
	end
	local model = part:FindFirstAncestorOfClass("Model")
	if OrbFactory.isOrbModel(model) then
		return model
	end
	return nil
end

return OrbFactory
