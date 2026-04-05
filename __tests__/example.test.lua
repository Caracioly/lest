local lest = require("lest")

lest.describe("example", function()
    lest.it("adds correctly", function()
        lest.expect(1 + 2).toBe(3)
    end)

    lest.it("compares table values", function()
        lest.expect({ a = 1, b = { c = 2 } }).toEqual({ a = 1, b = { c = 2 } })
    end)
end)
