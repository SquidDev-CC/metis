--[[- Extends the CC's [fs] library with additional utility functions.

This module re-exports any function defined in [fs], and so may shadow the [fs]
global.

```lua
local fs = require "metis.fs"
print(fs.exists("rom"))
```

[fs]: https://tweaked.cc/module/fs.html
]]

local expect = require "cc.expect".expect

--[[- Read a file into a string.

@tparam string filename The file to read.
@tparam[opt] boolean binary Whether to read this as a binary file.
@treturn[1] string The contents of the file.
@treturn[2] nil If the file could not be read.
@treturn string The error which occurred when reading.

@usage Read from `example.txt`.

    local fs = require "metis.fs"
    print(fs.read_file("example.txt"))
]]
local function read_file(filename, binary)
  expect(1, filename, "string")
  expect(2, binary, "boolean", "nil")

  local h, err = io.open(filename, binary and "rb" or "r")
  if not h then return nil, err end

  local contents = h:read("a")
  h:close()
  return contents
end

--[[- Write a file to a string.

@tparam string filename The file to read.
@tparam string contents The contents of the file.
@tparam[opt] boolean binary Whether to write this as a binary file.
@throws If the file could not be written to.

@usage Write to `example.txt`.

    local fs = require "metis.fs"
    fs.write_file("example.txt", "Hello, world!")
]]
local function write_file(filename, contents, binary)
  expect(1, filename, "string")
  expect(2, contents, "string")
  expect(3, binary, "boolean", "nil")

  local h, err = io.open(filename, binary and "wb" or "w")
  if not h then error(err, 2) end

  h:write(contents):close()
end

--[[- Walk a directory tree recursively, invoking a callback for every path found.

@tparam string root The directory to start walking from.
@tparam function(name: string, attributes:table):boolean|nil callback The
callback to invoke. This will be passed the file's _absolute_ path, and the
result of [fs.attributes].

When given a directory, the function may return `false` in order to skip
visiting its children.

[fs.attributes]: https://tweaked.cc/module/fs.html#v:attributes

@usage Print the size of every file on the computer, skipping `.git` directories
and the `rom`.

    local fs = require "metis.fs"
    fs.walk("/", function(path, info)
      if info.isDir then
        if fs.getName(path) == ".git" or path == "rom" then return false end
      else
        print(path .. " => " .. info.size)
      end
    end)
]]
local function walk(root, callback)
  expect(1, root, "string")
  expect(2, callback, "function")

  local queue, n = { fs.combine(root, "") }, 1
  while n > 0 do
    local path = queue[n]
    n = n - 1

    local ok, info = pcall(fs.attributes, path)
    if ok and callback(path, info) ~= false and info.isDir then
      for _, child in ipairs(fs.list(path)) do
        n = n + 1
        queue[n] = fs.combine(path, child)
      end
    end
  end
end

--[[- Recursively read all files and folders in a directory.

@tparam string root The directory to start walking from.
@treturn { [string] = table } A mapping of absolute file/folder names to their
[attributes](https://tweaked.cc/module/fs.html#v:attributes).

@see walk For finer-grain control.
]]
local function read_dirs(root)
  expect(1, root, "string")

  local out = {}
  walk(root, function(path, info) out[path] = info end)
  return out
end

local M = {
  read_file = read_file,
  write_file = write_file,
  walk = walk,
  read_dirs = read_dirs,
}

for k, v in pairs(fs) do M[k] = v end
return M
