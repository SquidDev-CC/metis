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

return {
  capture = capture,
}
