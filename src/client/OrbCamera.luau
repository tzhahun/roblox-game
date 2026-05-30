local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local OrbCamera = {}

local OFFSET = Vector3.new(0, 10, 18)

function OrbCamera.start()
	RunService.RenderStepped:Connect(function()
		local character = player.Character
		if not character or not character.PrimaryPart then
			return
		end

		local root = character:FindFirstChild("PlayerBall") or character.PrimaryPart
		if not root then
			return
		end
		local target = root.Position
		local desired = CFrame.new(target + OFFSET, target)
		camera.CameraType = Enum.CameraType.Scriptable
		camera.CFrame = camera.CFrame:Lerp(desired, 0.15)
	end)
end

return OrbCamera
