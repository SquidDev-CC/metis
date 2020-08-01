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

local packages = {}
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
      deps[#deps + 1] = "metis/" .. to_package(require)
    end
  end

  table.insert(packages, "metis/" .. to_package(module))

  io.write("name = ", to_package(module), "\n")
  io.write("\ttype = raw\n")
  io.write("\t\turl = https://raw.githubusercontent.com/SquidDev-CC/metis/dev/", file, "\n")
  io.write("\t\tfilename = ", file:sub(5), "\n")
  io.write("\ttarget = /usr/modules/\n")
  io.write("\tcategory = lib\n")
  io.write("\tversion = ", version, "\n")
  io.write("\tdependencies = ", #deps == 0 and "none" or table.concat(deps, " "), "\n")
  io.write("\tsize = ", #contents, "\n")
  io.write("end\n\n")
end

io.write("name = metis-full\n")
io.write("\ttype = meta\n")
io.write("\tcategory = lib\n")
io.write("\tversion = ", version, "\n")
io.write("\tdependencies = ", table.concat(packages, " "), "\n")
io.write("\tsize = 0\n")
io.write("end\n\n")
