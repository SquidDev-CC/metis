--- Run a program and capture its output
--
-- @tparam function(tbl:table, var:string, value:string) stub The active stub function.
-- @tparam function fn The function to run.
-- @param ... Arguments to this function.
-- @treturn { result = table, output = string, error = string, combined = string }
-- The various output streams and the function's return values.
local function capture(stub, fn, ...)
  local output, error, combined = {}, {}, {}

  local function out(stream, msg)
      table.insert(stream, msg)
      table.insert(combined, msg)
  end

  stub(_G, "print", function(...)
      for i = 1, select('#', ...) do
          if i > 1 then out(output, " ") end
          out(output, tostring(select(i, ...)))
      end
      out(output, "\n")
  end)

  stub(_G, "printError", function(...)
      for i = 1, select('#', ...) do
          if i > 1 then out(error, " ") end
          out(error, tostring(select(i, ...)))
      end
      out(error, "\n")
  end)

  stub(_G, "write", function(msg) out(output, tostring(msg)) end)

  local result = table.pack(fn(...))

  return {
      output = table.concat(output),
      error = table.concat(error),
      combined = table.concat(combined),
      result = result,
  }
end

local function empty_stub(stub)
  local x = {}
  local stub = stub(x, "x")
  stub.value = x.x
  return stub, x.x
end

local function testing(env, name, fun, build)
  local pp = require "cc.pretty"
  local function dump(x) return tostring(pp.pretty(x)) end

  env.describe(name, function()
    return build(function(exp, ...)
      local args, str_args = table.pack(...), table.pack(...)
      for i = 1, str_args.n do str_args[i] = dump(str_args[i]) end

      env.it(("%s(%s) == %s"):format(name, table.concat(str_args, ", "), dump(exp)), function()
        env.expect(fun(table.unpack(args, 1, args.n))):same(exp)
      end)
    end)
  end)
end

return {
  capture = capture,
  empty_stub = empty_stub,
  testing = testing,
}
