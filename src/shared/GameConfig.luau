-- Shared tuning knobs for Orb Knockout
local GameConfig = {}

-- true = default Roblox avatar in a translucent white ball; false = Orb Knockout mode
GameConfig.USE_PLAYER_BALL_SPAWN = true

GameConfig.ORB_SIZE = Vector3.new(4, 4, 4)
GameConfig.ORB_DENSITY = 0.6
GameConfig.ORB_FRICTION = 0.10
GameConfig.ORB_ELASTICITY = 0.85

GameConfig.PLATFORM_SIZE = Vector3.new(80, 2, 80)
GameConfig.PLATFORM_HEIGHT = 40
GameConfig.ARENA_CENTER = Vector3.new(0, GameConfig.PLATFORM_HEIGHT, 0)

GameConfig.SPAWN_RADIUS = 22
GameConfig.FALL_DISTANCE = 28 -- below platform surface → eliminated

GameConfig.MIN_BUMP_SPEED = 4
GameConfig.KNOCKBACK_SCALE = 5
GameConfig.BASE_KNOCKBACK = 12
GameConfig.BUMP_COOLDOWN = 0.12

GameConfig.ROUND_INTERMISSION = 5
GameConfig.MIN_PLAYERS_TO_START = 1 -- set to 2+ for production

GameConfig.DASH_COOLDOWN = 2.5
GameConfig.DASH_POWER = 55

-- Player ball mode (roll + knock off platform)
GameConfig.BALL_ROLL_SPEED = 60 -- forward / strafe
GameConfig.BALL_BACK_SPEED = 20 -- backward, or opposite after strafe/bump
GameConfig.BALL_OPPOSITE_WINDOW = 2.5 -- seconds to remember strafe / knock direction
GameConfig.BALL_ROLL_ACCEL = 0.12
GameConfig.BALL_GLIDE_DRAG = 0.992
GameConfig.BALL_ICE_FRICTION = 0.02
GameConfig.BALL_JUMP_IMPULSE = 48
GameConfig.BALL_RESPAWN_DELAY = 3

-- Portals (Workspace.GamePortals; aligned to map parts at runtime)
GameConfig.PORTAL1_NAME = "Portal1" -- cyan destination (no teleport trigger)
GameConfig.PORTAL2_NAME = "Portal2" -- blue entrance (one-way trigger)
GameConfig.PORTAL1_ANCHOR = "abc" -- Portal1 (cyan entrance) sits on this part/model
GameConfig.PORTAL2_ANCHOR = "StartingPlatform" -- Portal2 (blue exit) sits on this part/model

return GameConfig
