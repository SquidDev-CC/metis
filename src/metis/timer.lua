--- Utilities for working with timers.

local expect = require "cc.expect".expect

--- Run a function, waiting for it to complete or for a timer to expire.
--
-- This _does not_ terminate a function which is running. It must yield (e.g.
-- pull an event) in order to be interrupted.
--
-- @tparam number The time (in seconds) the function can run for before begin
-- stopped.
-- @tparam function fn The function to run.
-- @param ... Arguments to pass to the function.
-- @treturn[1] true If the function completes without timing out.
-- @return ... The return values of the function.
-- @treturn[2] false If the function times out.
-- @usage Wait for a "redstone" event for a maximum of 5 seconds.
--
--     local timeout = require "metis.timer".timeout
--     timeout(5, os.pullEvent, "redstone")
local function timeout(timeout, fn, ...)
  expect(1, timeout, "number")

  local timer = os.startTimer(timeout)
  local co = coroutine.create(fn)

  local result = table.pack(coroutine.resume(co, ...))

  while coroutine.status(co) ~= "dead" do
    local event = table.pack(os.pullEventRaw())
    if event[1] == "timer" and event[2] == timer then return false end

    if result[2] == nil or event[1] == "terminated" or event[1] == result[2] then
      result = table.pack(coroutine.resume(co, table.unpack(event, 1, event.n)))
    end
  end

  if not result[1] then error(result[2], 0) end
  return table.unpack(result, 1, result.n)
end

return { timeout = timeout }
