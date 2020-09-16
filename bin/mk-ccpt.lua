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

local build = os.getenv("GITHUB_RUN_NUMBER") or "0-dev"
local version = "1.0.0." .. build

if ... then io.output(...) end

local function to_package(dep)
  return dep:sub(7):gsub("%.", "-")
end

local modules = {}
with_command("git ls-files", function(handle)
  for file in handle:lines() do
    if file:sub(1, 4) == "src/" and file:sub(-4) == ".lua" then
      local module = file:sub(5, -5):gsub("/", ".")
      modules[module] = file
    end
  end
end)

io.write("{\n")
local packages = ""
for module, file in pairs(modules) do
  local contents = string.dump(loadfile(file))

  local deps = {}
  for require in contents:gmatch('(metis%.[a-z.]+)') do
    if not modules[require] then
      io.stderr:write(("Unknown module %q\n"):format(require))
      os.exit(1)
    end

    if not deps[require] then
      deps[require] = true
      deps[#deps + 1] = "ccpt:metis/" .. to_package(require)
    end
  end

  packages = packages .. '"ccpt:metis/' .. to_package(module) .. '",'

  io.write('\t"', to_package(module), '": {\n')
  io.write('\t\t"plugins": ["files"],\n')
  io.write('\t\t"version": "' .. version .. '",\n')
  io.write('\t\t"files": [\n')
  io.write('\t\t\t["https://raw.githubusercontent.com/SquidDev-CC/metis/dev/' .. file .. '","/usr/modules/' .. file:sub(5) .. '"]\n')
  io.write('\t\t],\n')
  depstring = ""
  for _,i in ipairs(deps) do
    depstring = depstring .. '"' .. i .. '", '
  end
  if deps ~= 0 then
    depstring = depstring:sub(1,-3)
  end
  io.write('\t\t"dependencies": [' .. depstring .. ']\n')
  io.write('\t},\n')
end

packages = packages:sub(1,-2)

io.write('\t"metis-full": {\n')
io.write('\t\t"plugins": [],\n')
io.write('\t\t"version": "' .. version .. '",\n')
io.write('\t\t"dependencies": [' .. packages .. '],\n')
io.write('\t\t"description":  "All packages of metis"\n')
io.write('\t}\n')

io.write("}")
