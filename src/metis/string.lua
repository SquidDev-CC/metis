--[[- Extends the default @{string} library with additional utility functions.

This module re-exports any function defined in @{string}, and so may shadow the
@{string} global. This _does not_ extend the string metatable though, so you
cannot use colon notation (e.g. `("hello"):sub(...)`).

```lua
local string = require "metis.string"
print(string.sub("hello", 1, 1))
```
]]

local expect = require "cc.expect".expect

--- Determine if a string starts with the prefix.
--
-- @tparam string str The string to check.
-- @tparam string prefix The prefix the string may start with.
-- @return boolean If this string starts with the prefix.
local function starts_with(str, prefix)
  return #str >= #prefix and str:sub(1, #prefix) == prefix
end

--- Determine if a string ends with the suffix.
--
-- @tparam string str The string to check.
-- @tparam string suffix The suffix the string may end with.
-- @return boolean If this string ends with the suffix.
local function ends_with(str, suffix)
  return #str >= #suffix and str:sub(-#suffix) == suffix
end

--[[- Split a string according to a deliminator.

Note, the deliminator is a [Lua pattern][pattern]

[pattern]: https://www.lua.org/manual/5.3/manual.html#6.4.1

@tparam string str The string to split.
@tparam string deliminator The pattern to split this string on.
@tparam[opt] boolean plain Treat the deliminator as a plain string, rather than a pattern.
@tparam[opt] number limit The maximum number of elements in the returned list.
@usage Split a string into words.

    local string = require "metis.string"
    print(textutils.serialize(string.split("This is a sentence.", "%s+")))
    -- => { "This", "is", "a" , "sentence." }

@usage Split a string by "-" into at most elements.

    local string = require "metis.string"
    print(textutils.serialize(string.split("a-separated-string-of-sorts", "-", true, 3)))
    -- => { "a", "separated", "string-of-sorts" }
]]
local function split(str, deliminator, plain, limit)
  expect(1, str, "string")
  expect(2, deliminator, "string")
  expect(3, plain, "boolean", "nil")
  expect(4, limit, "number", "nil")

  local out, out_n, pos = {}, 0, 1
  while not limit or out_n < limit - 1 do
    local start, finish = str:find(deliminator, pos, plain)
    if not start then break end

    out_n = out_n + 1
    out[out_n] = str:sub(pos, start - 1)
    pos = finish + 1
  end

  if pos == 1 then return { str } end

  out[out_n + 1] = str:sub(pos)
  return out
end

local pattern_escapes = {
  ["^"] = "%^", ["$"] = "%$", ["("] = "%(", [")"] = "%)",
  ["%"] = "%%", ["."] = "%.", ["["] = "%[", ["]"] = "%]",
  ["*"] = "%*", ["+"] = "%+", ["-"] = "%-", ["?"] = "%?",
  ["\0"] = "%z",
}

--[[- Escape a string for using in a pattern

@tparam string pattern The string to escape
@treturn string The escaped pattern.

@usage Escape the string "1.0 You Are (Not) Alone"

    local string = require "metis.string"
    print(string.escape_pattern("1.0 You Are (Not) Alone"))
    -- => "1%.0 You are %(Not%) Alone"
]]
local function escape_pattern(pattern)
  return (pattern:gsub(".", pattern_escapes))
end

local M = {
  starts_with = starts_with,
  ends_with = ends_with,
  split = split,
  escape_pattern = escape_pattern,
}
for k, v in pairs(string) do M[k] = v end
return M
