local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Rojo: src/server becomes one Script named "Server"; modules are script.* children (not script.Parent.*).
local GameConfig = require(ReplicatedStorage.Shared.GameConfig)
local PlayerBallSpawn = require(script.PlayerBallSpawn)
local RoundManager = require(script.RoundManager)

if GameConfig.USE_PLAYER_BALL_SPAWN then
	PlayerBallSpawn.init()
	print("[PlayerBall] Server ready — roll inside your ball on your map.")
else
	Players.CharacterAutoLoads = false
	RoundManager.init()
	print("[Orb Knockout] Server ready — knock other orbs off the platform!")
end
