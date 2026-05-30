local GameConfig = require(script.Parent.GameConfig)

local Knockback = {}

-- Impulse vectors applied to each orb after a bump (A away from B, B away from A).
function Knockback.computeBump(velocityA: Vector3, velocityB: Vector3, positionA: Vector3, positionB: Vector3): (Vector3?, Vector3?)
	local offset = positionA - positionB
	if offset.Magnitude < 0.01 then
		return nil, nil
	end

	local normal = offset.Unit
	local relativeVelocity = velocityA - velocityB
	local approachSpeed = relativeVelocity:Dot(normal)

	if approachSpeed < GameConfig.MIN_BUMP_SPEED then
		return nil, nil
	end

	local impulse = normal * (approachSpeed * GameConfig.KNOCKBACK_SCALE + GameConfig.BASE_KNOCKBACK)
	return impulse, -impulse
end

return Knockback
