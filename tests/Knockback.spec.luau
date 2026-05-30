local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Knockback = require(ReplicatedStorage.Shared.Knockback)

return function()
	describe("Knockback", function()
		it("applies impulse when orbs collide fast enough", function()
			local velA = Vector3.new(20, 0, 0)
			local velB = Vector3.new(-5, 0, 0)
			local impulseA, impulseB = Knockback.computeBump(
				velA,
				velB,
				Vector3.new(0, 0, 0),
				Vector3.new(-4, 0, 0)
			)
			expect(impulseA).to.be.ok()
			expect(impulseB).to.be.ok()
			expect(impulseA.Magnitude).to.be.near(impulseB.Magnitude, 0.01)
		end)

		it("ignores slow bumps", function()
			local impulseA, impulseB = Knockback.computeBump(
				Vector3.new(1, 0, 0),
				Vector3.new(0, 0, 0),
				Vector3.new(0, 0, 0),
				Vector3.new(-2, 0, 0)
			)
			expect(impulseA).to.equal(nil)
			expect(impulseB).to.equal(nil)
		end)
	end)
end
