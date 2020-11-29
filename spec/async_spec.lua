describe("metis.async", function()
  local async = require "metis.async"

  it("runs multiple threads at once", function()
    async(function() sleep(0.5) end)
    async(function() sleep(0.5) end)

    local start = os.clock()
    async.run()
    local finish = os.clock()

    assert(finish - start < 0.55, ("ran from %.2f to %.2f"):format(start, finish))
  end)

  it("throws errors on awaiting", function()
    local a = async(function() error("oh no", 0) end)
    async.run()
    expect.error(async.await, a):eq("oh no")
  end)

  it("throws errors on awaiting (after yields)", function()
    local a = async(function() sleep(0) error("oh no", 0) end)
    async.run()
    expect.error(async.await, a):eq("oh no")
  end)
end)
