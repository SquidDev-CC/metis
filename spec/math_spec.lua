describe("metis.math", function()
  local math = require "metis.math"

  it("clamp", function()
    local out = {}
    for i = 1, 10 do out[i] = math.clamp(i, 3, 7) end
    expect(out):same { 3, 3, 3, 4, 5, 6, 7, 7, 7, 7 }
  end)

  it("wrap", function()
    local out = {}
    for i = 1, 10 do out[i] = math.wrap(i, 3, 7) end
    expect(out):same { 6, 7, 3, 4, 5, 6, 7, 3, 4, 5 }
  end)
end)
