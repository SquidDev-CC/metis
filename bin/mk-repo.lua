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
local url = "https://raw.githubusercontent.com/SquidDev-CC/metis/dev/"


local function to_package(dep)
  return dep:sub(7):gsub("%.", "-")
end

local function map_concat(tbls, fn, sep)
  local out = ""
  for i = 1, #tbls do
    if i > 1 then out = out .. sep end
    out = out .. fn(tbls[i])
  end
  return out
end

local function packman_name(x) return "metis/" .. x end
local function ccpt_name(x) return ("%q"):format("ccpt:metis/" .. x) end

local kind, filename = ...
if not filename then kind, filename = nil, kind end
if not kind then kind = "packman" end

if kind ~= "packman" and kind ~= "ccpt" then
  io.stderr:write("Unknown repo kind ", kind, "\n")
  return os.exit(1)
end

if filename and filename ~= "-" then io.output(filename) end

local modules = {}
with_command("git ls-files", function(handle)
  for file in handle:lines() do
    if file:sub(1, 4) == "src/" and file:sub(-4) == ".lua" then
      local module = file:sub(5, -5):gsub("/", ".")
      modules[module] = file
    end
  end
end)

if kind == "ccpt" then
  io.write("{\n")
end

local packages = {}
for module, file in pairs(modules) do
  local contents = string.dump(loadfile(file))

  table.insert(packages, (to_package(module)))

  local deps = {}
  for require in contents:gmatch('(metis%.[a-z.]+)') do
    if not modules[require] then
      io.stderr:write(("Unknown module %q\n"):format(require))
      os.exit(1)
    end

    if not deps[require] then
      deps[require] = true
      deps[#deps + 1] = to_package(require)
    end
  end

  if kind == "packman" then
    io.write("name = ", to_package(module), "\n")
    io.write("\ttype = raw\n")
    io.write("\t\turl = ", url, file, "\n")
    io.write("\t\tfilename = ", file:sub(5), "\n")
    io.write("\ttarget = /usr/modules/\n")
    io.write("\tcategory = lib\n")
    io.write("\tversion = ", version, "\n")
    io.write("\tdependencies = ", #deps == 0 and "none" or map_concat(deps, packman_name, " "), "\n")
    io.write("\tsize = ", #contents, "\n")
    io.write("end\n\n")

  elseif kind == "ccpt" then
    io.write('  "', to_package(module), '": {\n')
    io.write('    "plugins": ["files"],\n')
    io.write('    "version": "' .. version .. '",\n')
    io.write('    "files": [\n')
    io.write('      ["', url, file, '","/usr/modules/', file:sub(5), '"]\n')
    io.write('    ],\n')
    io.write('    "dependencies": [', map_concat(deps, ccpt_name, ", "), ']\n')
    io.write('  },\n')
  end
end

if kind == "packman" then
  io.write("name = metis-full\n")
  io.write("\ttype = meta\n")
  io.write("\tcategory = lib\n")
  io.write("\tversion = ", version, "\n")
  io.write("\tdependencies = ", map_concat(packages, packman_name, " "), "\n")
  io.write("\tsize = 0\n")
  io.write("end\n\n")
elseif kind == "ccpt" then
  io.write('  "metis-full": {\n')
  io.write('    "plugins": [],\n')
  io.write('    "version": "' .. version .. '",\n')
  io.write('    "dependencies": [', map_concat(packages, ccpt_name, ", "), '],\n')
  io.write('    "description":  "All packages of metis"\n')
  io.write('  }\n')
  io.write("}\n")

end
