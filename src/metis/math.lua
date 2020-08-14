--[[- Extends the default @{math} library with additional utility functions.

This module re-exports any function defined in @{math}, and so may shadow the
@{math} global.

```lua
local math = require "metis.math"
print(math.min(0, 10))
```
]]

--[[- Clamp a value within a range. This limits the given `value` to be between
`min` and `max` (inclusive).

@tparam number value The value to clamp.
@tparam number min The lower bound of the permitted values.
@tparam number max The upper bound of the permitted values.
@treturn number The clamped value.
@usage Clamp a value between 3 and 7.

    local clamp = require "metis.math".clamp
    for i = 1, 10 do
      io.write(clamp(i, 3, 7), " ")
    end
    -- 3 3 3 4 5 6 7 7 7 7
]]
local function clamp(value, min, max)
  if value < min then return min end
  if value > max then return max end
  return value
end

--[[- Wrap a value around a range. This is equivalent to the modulo operator
(`%`), but for any lower and upper bound.

@tparam number value The value to wrap.
@tparam number min The lower bound of the permitted values.
@tparam number max The upper bound of the permitted values.
@usage Wrap a value between 3 and 7.

    local wrap = require "metis.math".wrap
    for i = 1, 10 do
      io.write(wrap(i, 3, 7), " ")
    end
    -- 6 7 3 4 5 6 7 3 4 5
]]
local function wrap(value, min, max)
  return (value - min) % (max - min + 1) + min
end

local M = {
  clamp = clamp,
  wrap = wrap,
}
for k, v in pairs(math) do M[k] = v end
return M
