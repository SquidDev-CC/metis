describe("metis.timer", function()
  describe("timeout", function()
    local timeout = require "metis.timer".timeout

    it("terminates a function", function()
      local then_ = os.clock()
      local ok = timeout(0, sleep, 1)
      local now = os.clock()

      expect(ok):eq(false)
      if now - then_ > 0.1 then fail("Slept for too long") end
    end)

    it("allows a function to run", function()
      os.queueEvent("foo")
      os.queueEvent("bar")
      os.queueEvent("baz")
      local got_event = false
      local ok = timeout(1, function()
        os.pullEvent()
        expect(os.pullEvent("baz")):eq("baz")
        got_event = true
      end)

      expect(ok):eq(true)
      expect(got_event):eq(true)
    end)

    it("returns its result", function()
      local res = { timeout(1, function() return 2, "foo" end) }
      expect(res):same { true, 2, "foo" }
    end)
  end)
end)
