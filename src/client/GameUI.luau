local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local GameUI = {}

function GameUI.start()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	local screen = Instance.new("ScreenGui")
	screen.Name = "OrbKnockoutUI"
	screen.ResetOnSpawn = false
	screen.Parent = playerGui

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.fromOffset(420, 48)
	title.Position = UDim2.new(0.5, -210, 0, 16)
	title.BackgroundTransparency = 0.35
	title.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Font = Enum.Font.GothamBold
	title.TextSize = 22
	title.Text = "Orb Knockout"
	title.Parent = screen

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = title

	local status = Instance.new("TextLabel")
	status.Name = "Status"
	status.Size = UDim2.fromOffset(420, 36)
	status.Position = UDim2.new(0.5, -210, 0, 68)
	status.BackgroundTransparency = 0.45
	status.BackgroundColor3 = Color3.fromRGB(30, 30, 45)
	status.TextColor3 = Color3.fromRGB(220, 230, 255)
	status.Font = Enum.Font.Gotham
	status.TextSize = 18
	status.Text = "Connecting…"
	status.Parent = screen

	local corner2 = corner:Clone()
	corner2.Parent = status

	local hint = Instance.new("TextLabel")
	hint.Size = UDim2.fromOffset(420, 28)
	hint.Position = UDim2.new(0.5, -210, 1, -44)
	hint.BackgroundTransparency = 1
	hint.TextColor3 = Color3.fromRGB(200, 200, 210)
	hint.Font = Enum.Font.Gotham
	hint.TextSize = 16
	local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
	if GameConfig.USE_PLAYER_BALL_SPAWN then
		title.Text = "Ball Knockout"
		hint.Text = "WASD to roll · Space to jump · Q to dash — bump others off the platform!"
	else
		hint.Text = "WASD to move · Space to jump · Q to dash into others"
	end
	hint.Parent = screen

	local remotes = ReplicatedStorage:WaitForChild("Remotes", 30)
	if not remotes then
		return
	end

	local gameState = remotes:WaitForChild("GameState", 10)
	if not gameState then
		return
	end

	gameState.OnClientEvent:Connect(function(payload)
		local aliveText = ""
		if payload.alive and payload.alive > 0 then
			aliveText = ` · {payload.alive} orb(s) left`
		end
		status.Text = (payload.message or "") .. aliveText
	end)
end

return GameUI
