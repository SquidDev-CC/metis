--[[- @{metis.input.keybinding} provides a mechanism for handling keyboard
shortcuts. One provides a table of keybindings and their corresponding action,
and then passes events to it.

## Keybinding syntax
Keybindings are written in an Emacs-esque notation, specifying the modifier keys
and then the actual key. For instance, `C-M-underscore` means the "Control",
"Meta" (or "Alt") and "underscore" keys must be pressed.

@usage

```lua
local kb = require "metis.input.keybinding".create {
  ["C-M-x"] = function() print("Pressed Ctrl, Alt and 'x'") end,
  char = function(c) print("Typed character " .. c) end,
}

while true do kb:event(os.pullEvent()) end
```

]]

local exp = require "cc.expect"
local expect, field = exp.expect, exp.field

local function update_modifier(self)
  local down = self._down
  local modifier = 0
  if down[keys.leftCtrl] or down[keys.rightCtrl] then modifier = modifier + 1 end
  if down[keys.leftAlt] or down[keys.rightAlt]   then modifier = modifier + 2 end
  self._modifier = modifier
end

local function void() end

local function parse_binding(str)
  local pos, len = 1, #str
  local modifier = 0
  while pos <= len do
    local mod = str:match("^([A-Z])%-", pos)
    if not mod then break end

    if mod == "C" then
      modifier = bit32.bor(modifier, 1)
    elseif mod == "M" then
      modifier = bit32.bor(modifier, 2)
    else
      error(("Unknown modifier %q in binding %q"):format(modifier, str))
    end

    pos = pos + 2
  end

  if pos > len then error(("Malformed binding %q"):format(str)) end

  local name = str:sub(pos, len)
  local key = keys[name]
  if type(key) ~= "number" then
    error(("Unknown key %q in binding %q"):format(name, str))
  end

  return modifier, key
end

--- The keybinding processor. This accepts events, determines what keys are
-- pressed, and dispatches the appropriate action.
--
-- @type Keybindings
local Keybindings = {}
local keybindings_mt = { __index = Keybindings }

--- Process a `char` event.
--
-- @tparam string chr The character which has been typed.
-- @param ... Additional arguments which will be passed to the associated action.
-- @return The result of the associated keybinding's action, or @{nil}.
function Keybindings:char(chr, ...)
  -- If we've got the alt key down, and we're not pressing a key which is used
  -- in binding with alt, treat it as a normal char. This is a little ugly, as
  -- it means that unhandled keys are "typed", but ensures that Alt Gr correctly
  -- types characters.
  local modifier = self._modifier
  if self._on_char and (modifier == 0 or modifier == 3 or modifier == 2 and not self._meta_keys[chr]) then
    return self._on_char(chr, ...)
  end
end

--- Process a `key` event.
--
-- @tparam number key The key which has been pressed.
-- @param ... Additional arguments which will be passed to the associated action.
-- @return The result of the associated keybinding's action, or @{nil}.
function Keybindings:key(key, ...)
  if key == keys.leftCtrl or key == keys.rightCtrl or key == keys.leftAlt or key == keys.rightAlt then
    self._down[key] = true
    update_modifier(self)
  end

  local fn = self._bindings[self._modifier][key]
  if fn then return fn(...) end
end

--- Process a `key_up` event.
--
-- @tparam number key The key which has been released.
function Keybindings:key_up(key)
  if key == keys.leftCtrl or key == keys.rightCtrl or key == keys.leftAlt or key == keys.rightAlt then
    self._down[key] = false
    update_modifier(self)
  end
end

--- Process an event. This dispatches to the @{Keybindings:key},
-- @{Keybindings:key_up} or @{Keybindings:char} as appropriate.
--
-- Repeat key events will be passed to @{Keybindings:key} by default. If this is
-- not desired, your keybindings should either check if this event is a repeat
-- (the first argument will be {@true}) or roll your own version of `event`.
--
-- @tparam string event The name of the event.
-- @param ... Additional event arguments.
-- @usage kb:event(os.pullEvent())
function Keybindings:event(event, ...)
  if event == "key" then
    return self:key(...)
  elseif event == "key_up" then
    return self:key_up(...)
  elseif event == "char" then
    return self:char(...)
  end
end

--- Reset the set of pressed keys within the keybinding manager. This may be
-- used if a window becomes unfocused, and so `key_up` events will no longer be
-- sent to it.
function Keybindings:reset()
  for k in pairs(self._down) do self._down[k] = false end
  update_modifier(self)
end

--- Create a new group of keybindings.
--
-- @tparam { [string] = function } binds A mapping of keybinding names to
-- functions. The special name "char" may be used when a character is typed.
-- @treturn Keybindings The constructed keybinding handler.
local function create(binds)
  expect(1, binds, "table")
  local char = field(binds, "char", "function", "nil") or void
  local bindings = { [0] = {}, {}, {}, {} }

  local meta_chars = {}
  for k in pairs(binds) do
    if k ~= "char" then
      if type(k) ~= "string" then error(("Bad key %s of type %s"):format(k, type(k)), 2) end
      local action = field(binds, k, "function")

      local mod, key = parse_binding(k)
      if bindings[mod][key] then error(("Duplicate bindings for %s"):format(k), 2) end
      bindings[mod][key] = action

      if mod == 2 then
        local name = keys.getName(key)
        if name and #name == 1 then meta_chars[name] = true end
      end
    end
  end

  return setmetatable({
    _down = {}, _modifier = 0, _bindings = bindings, _meta_keys = meta_chars,
    _on_char = char,
  }, keybindings_mt)
end

return { create = create }
