-- Run in Studio after Rojo sync (Play or command bar).
-- Remove or disable in published builds.

local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function runTests()
	local ok, TestEZ = pcall(function()
		return require(ReplicatedStorage.Packages.TestEZ)
	end)
	if not ok then
		warn("[TestRunner] Install Wally packages first: wally install")
		return
	end

	local testsFolder = ServerStorage:FindFirstChild("Tests")
	if not testsFolder then
		warn("[TestRunner] No Tests folder — check default.project.json")
		return
	end

	local results = TestEZ.TestBootstrap:run({ testsFolder })
	print("[TestRunner] passed:", results.successCount, "failed:", results.failureCount)
end

runTests()
