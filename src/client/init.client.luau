local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Rojo: src/client becomes one LocalScript named "Client"; modules are script.* children.
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

if GameConfig.USE_PLAYER_BALL_SPAWN then
	local OrbCamera = require(script.OrbCamera)
	local DashInput = require(script.DashInput)

	OrbCamera.start()
	DashInput.start()

	-- Remove on-screen status UI if it was created earlier.
	local player = game:GetService("Players").LocalPlayer
	local gui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("OrbKnockoutUI")
	if gui then
		gui:Destroy()
	end

	print("[PlayerBall] Client ready")
else
	local OrbCamera = require(script.OrbCamera)
	local GameUI = require(script.GameUI)
	local DashInput = require(script.DashInput)

	OrbCamera.start()
	GameUI.start()
	DashInput.start()

	print("[Orb Knockout] Client ready")
end
