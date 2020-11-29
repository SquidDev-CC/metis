--[[- A basic system for running multiple tasks at the same time.

One creates asynchronous tasks with @{async}, whose result can be fetched with
@{await}.

@usage

```lua
local async = require "metis.async"
async.run(function()
  local left = async(function()
    print("Start 1")
    sleep(0.5)
    print("Done 1")

    return 123
  end)
  local right = async(function()
    print("Start 2")
    sleep(1)

    error("Oh no")
    print("Done 2")

    return 456
  end)

  print("Awaiting")
  local left, right = left:await(), right:await()

  print(left .. right)
end)
```
]]

local expect = require "cc.expect".expect
local pack = table.pack

local first_task, last_task = false, false

local function pack_ok(ok, ...) return ok, pack(...) end

local function run_task(task, ...)
  if not task.alive then error("Cannot run dead task", 2) end

  local ok, result = pack_ok(coroutine.resume(task.co, ...))

  if not ok then
    task.alive = false
    task.error = true
    task.result = result[1]
  elseif coroutine.status(task.co) == "dead" then
    task.alive = false
    task.result = result
  elseif type(result[1]) == "string" then
    task.result = result[1]
  else
    task.result = false
  end

  if not task.alive then
    if task._previous then task._previous._next = task._next else first_task = task._next end
    if task._next then task._next._previous = task._previous else last_task = task._previous end
    task._next, task._previous = false, false
  end

  return task
end

--- An asynchronous task.
--
-- @type Task
local Task = {}
local task_mt = {
  __index = Task,
  __tostring = function(self)
    if self.alive then
      return ("Task [%s]"):format(self.co)
    elseif self.error then
      return ("Task (error) [%s]"):format(self.result)
    else
      return ("Task (done) [%s]"):format(self.result)
    end
  end,
}

--- Run a function in the background.
--
-- @tparam function() f The function to run
-- @treturn Task The generated task.
local function async(f)
  expect(1, f, "function")

  local task = setmetatable({
    co = coroutine.create(f),
    alive = true, error = false, result = false,
    _next = false, _previous = last_task,
  }, task_mt)

  if last_task then last_task._next = task else first_task = task end
  last_task = task

  return run_task(task)
end

--- Wait for a task to finish.
-- @tparam Task task The task to await on.
-- @return ... The result of running this task.
-- @throws If the underlying task errored.
-- @throws If the "terminate" event was found.
local function await(task)
  if getmetatable(task) ~= task_mt then expect(1, task, "Task") end

  while task.alive do os.pullEvent("task_done") end

  if task.error then
    error(task.result, 0)
  else
    return table.unpack(task.result, 1, task.result.n)
  end
end

Task.await = await

local running = false

--[[- Start the task queue. This can either be given a function (which should
run the main body of your function), or called as the last statement in your
program.

Tasks will **not** be run until this function is called, so you should not
@{await} (or ideally create any tasks) until the queue is created.

@return The result of the given function.
@throws If the underlying function throws.
@throws If trying to run multiple task queues at once.
]]
local function run(f)
  expect(1, f, "function", "nil")
  if running then error("Cannot run the task queue multiple times", 2) end
  running = true

  local main_task
  if f then main_task = async(f) end

  while last_task do
    local event = pack(coroutine.yield())
    local event_name = event[1]
    local had_finished = false

    local task = first_task
    while task do
      local next = task._next

      if not task.result or task.result == event_name or event_name == "terminate" then
        run_task(task, table.unpack(event, 1, event.n))
        if not task.alive then had_finished = true end
      end

      task = next
    end

    if had_finished then os.queueEvent("task_done") end
  end

  running = false

  if main_task then
    if main_task.alive then assert(false, "imposible: task cannot be alive") end
    return main_task:await()
  end
end

local out = { async = async, await = await, run = run }
setmetatable(out, { __call = function(_, ...) return async(...) end })
return out
