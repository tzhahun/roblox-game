local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Remotes = {}

function Remotes.ensure()
	local folder = ReplicatedStorage:FindFirstChild("Remotes")
	if not folder then
		folder = Instance.new("Folder")
		folder.Name = "Remotes"
		folder.Parent = ReplicatedStorage
	end

	local function remote(name: string, className: string)
		local existing = folder:FindFirstChild(name)
		if existing then
			return existing
		end
		local instance = Instance.new(className)
		instance.Name = name
		instance.Parent = folder
		return instance
	end

	Remotes.GameState = remote("GameState", "RemoteEvent")
	Remotes.Dash = remote("Dash", "RemoteEvent")
	return Remotes
end

return Remotes
