#!/usr/bin/env lua

local function with_command(command, fn)
  io.stderr:write("> ", command, "\n")
  local handle, err = io.popen(command)
  if not handle then
    io.stderr:write(err)
    os.exit(1)
  end

  local result = fn(handle)
  handle:close()

  return result
end

if ... then io.output(...) end

io.write("local modules = {\n")
with_command("git ls-files", function(handle)
  for file in handle:lines() do
    if file:sub(1, 4) == "src/" and file:sub(-4) == ".lua" then
      local module = file:sub(5, -5):gsub("/", ".")
      io.stderr:write(("Adding %q as %q\n"):format(file, module))
      io.write(("  [%q] = %q,\n"):format(module, file))
    end
  end
end)
io.write("}\n")

local sha = with_command("git rev-parse HEAD", function(h) return h:read("*l") end)

io.write([[
package.loaders[#package.loaders + 1] = function(name)
  local path = modules[name]
  if not path then return nil, "not a metis module" end

  local local_path = "/.cache/metis/]] .. sha .. [[/" .. path
  if not fs.exists(local_path) then
    local url = "https://raw.githubusercontent.com/SquidDev-CC/metis/]] .. sha .. [[/" .. path
    local request, err = http.get(url)
    if not request then return nil, "Cannot download " .. url .. ": " .. err end

    local out = fs.open(local_path, "w")
    out.write(request.readAll())
    out.close()

    request.close()
  end


  local fn, err = loadfile(local_path, nil, _ENV)
  if fn then return fn, local_path else return nil, err end
end

return require
]])
