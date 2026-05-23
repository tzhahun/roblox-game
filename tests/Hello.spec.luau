local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Hello = require(ReplicatedStorage.Shared.Hello)

return function()
	describe("Hello", function()
		it("should greet by name", function()
			expect(Hello.greet("World")).to.equal("Hello, World!")
		end)
	end)
end
