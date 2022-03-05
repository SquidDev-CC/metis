--[[- An extension of CC's builtin `read` function (and @{io.read}), and
utilities to work with it.

@usage Prompt a user for a password. The typed input will be written with `*`s
instead.

    local readline = require "metis.input.readline"
    io.write("Enter password> ")
    local pw = readline.read { replace_char = "*" }
    print("Entered " .. pw)

@usage A basic REPL with history, which just prints the output.

    local readline = require "metis.input.readline"
    local history = {}
    while true do
      io.write("> ")
      local line = readline.read { history = history }
      if line == nil then break end
      readline.insert_history(history, line)
      print(line)
    end

@usage Reads a string, completing to a list of foods.

    local readline = require "metis.input.readline"
    local completion = require "cc.completion"
    local choices = { "pizza", "calzone", "pasta" }
    readline.read {
      complete = function(line) return completion.choice(line, choices) end,
    }

@usage Highlights the word "foo".

    local readline = require "metis.input.readline"
    readline.read {
      highlight = function(line, pos)
        local next, fin = line:find("foo", pos)
        if not next then return #line, colours.white -- No more "foo"s
        elseif next == pos then return fin, colours.yellow -- Highlight this "foo"
        else return next - 1, colours.white -- Highlight until the next "foo"
        end
      end
    }
]]

local exp = require "cc.expect"
local expect, field = exp.expect, exp.field
local math = require "metis.math"

local function void() end

local function redraw(self, clear)
  local cursor_pos = self.pos - self.scroll
  if self.start_x + cursor_pos >= self.width then
    -- We've moved beyond the RHS, ensure we're on the edge.
    self.scroll = self.start_x + self.pos - self.width
  elseif cursor_pos < 0 then
    -- We've moved beyond the LHS, ensure we're on the edge.
    self.scroll = self.pos
  end

  local _, cy = term.getCursorPos()
  term.setCursorPos(self.start_x, cy)
  local replace = clear and " " or self.replace_char
  local line, scroll, highlight = self.line, self.scroll, self.highlight

  if highlight and not clear then
    -- We've a highlighting function: step through each line of input
    local old_col = term.getTextColor()
    local hl_pos, hl_max, hl_col = 1, #line, old_col
    while hl_pos <= hl_max do
      local next_pos, next_col = highlight(line, hl_pos)
      if next_pos < hl_pos then error("Highlighting function consumed no input") end

      if next_pos >= scroll + 1 then
        if next_col ~= hl_col then term.setTextColor(next_col) hl_col = next_col end
        if replace then
          term.write(string.rep(replace, next_pos - math.max(scroll + 1, hl_pos) + 1))
        else
          term.write(string.sub(line, math.max(scroll + 1, hl_pos), next_pos))
        end
      end

      hl_pos = next_pos + 1
    end
    term.setTextColor(old_col)
  else
    -- If we've no highlighting function, we can go the "fast" path.
    if replace then
      term.write(string.rep(replace, math.max(#line - scroll, 0)))
    else
      term.write(string.sub(line, scroll + 1))
    end
  end

  if self.current_completion then
    local completion = self.completions[self.current_completion]
    local old_text, old_bg
    if not clear then
      old_text = term.getTextColor()
      old_bg = term.getBackgroundColor()
      if self.complete_fg > -1 then term.setTextColor(self.complete_fg) end
      if self.complete_bg > -1 then term.setBackgroundColor(self.complete_bg) end
    end
    if replace then
      term.write(string.rep(replace, #completion))
    else
      term.write(completion)
    end
    if not clear then
      term.setTextColor(old_text)
      term.setBackgroundColor(old_bg)
    end
  end

  term.setCursorPos(self.start_x + self.pos - scroll, cy)
end

local function clear(self) redraw(self, true) end

local function uncomplete(self)
  self.completions = nil
  self.current_completion = nil
end

local function reset(self)
  clear(self)
  uncomplete(self)
  redraw(self)
end

local function recomplete(self)
  if self.complete and self.pos == #self.line then
    local completions = self.complete(self.line)
    if completions and #completions > 0 then
      self.current_completion = 1
      self.completions = completions
      return
    end
  end

  self.current_completion = nil
  self.completions = nil
end

local function set_line(self, line)
  self.line = line
  self.changed(line)
end

local function insert_line(self, txt)
  if txt == "" then return end

  clear(self)

  local line, pos = self.line, self.pos
  set_line(self, line:sub(1, pos) .. txt .. line:sub(pos + 1))
  self.pos = pos + #txt

  recomplete(self)
  redraw(self)
end

--- Accept the currently selected completion and continue.
local function accept_completion(self)
  if not self.current_completion then return end

  clear(self)

  -- TODO: Smarter completions
  set_line(self, self.line .. self.completions[self.current_completion])
  self.pos = #self.line
  recomplete(self)
  redraw(self)
end

--- Attempt to find the position of the next word
local function next_word(self)
  local offset = self.line:find("%w%W", self.pos + 1)
  if offset then return offset else return #self.line end
end

--- Attempt to find the position of the previous word
local function prev_word(self)
  local offset = 1
  while offset <= #self.line do
    local nNext = self.line:find("%W%w", offset)
    if nNext and nNext < self.pos then
      offset = nNext + 1
    else
      break
    end
  end
  return offset - 1
end

--- Move the cursor right, or accept autocompletion if on the last position.
local function move_right(self)
  if self.pos < #self.line then
    clear(self)
    self.pos = self.pos + 1
    recomplete(self)
    redraw(self)
  else
    accept_completion(self)
  end
end

--- Build a function which updates the cursor according to a specific function.
local function move_to(fn)
  return function(self)
    local pos = fn(self)
    if pos == self.pos then return end

    clear(self)
    self.pos = pos
    recomplete(self)
    redraw(self)
  end
end

local function left(self) return math.max(0, self.pos - 1) end
local function start() return 0 end
local function finish(self) return #self.line end

local function on_word(fn)
  return function(self)
    local line, pos = self.line, self.pos
    if pos >= #line then return end

    local next = next_word(self)
    set_line(self, line:sub(1, pos) .. fn(line:sub(pos + 1, next)) .. line:sub(next + 1))
    self.pos = next
    reset(self)
  end
end

local function kill(self, text)
  if text == "" then return end
  self.last_killed = text
end

local function kill_region(self, from, to)
  if self.pos <= 0 then return end
  if from >= to then return end

  clear(self)
  kill(self, self.line:sub(from + 1, to))
  set_line(self, self.line:sub(1, from) .. self.line:sub(to + 1))
  self.pos = from
  recomplete(self)
  redraw(self)
end

local function kill_before(fn)
  return function(self)
    if self.pos <= 0 then return end
    return kill_region(self, fn(self), self.pos)
  end
end

local function kill_after(fn)
  return function(self)
    if self.pos >= #self.line then return end
    return kill_region(self, self.pos, fn(self))
  end
end

local function adjust_completion(delta)
  return function(self)
    if self.current_completion then
      clear(self)
      self.current_completion = math.wrap(self.current_completion + delta, 1, #self.completions)
      redraw(self)
    elseif self.history then
      local history_n = #self.history
      if history_n == 0 then return end

      local new_pos = math.clamp((self.history_pos or history_n + 1) + delta, 1, history_n + 1)
      if new_pos == self.history_pos then return end

      clear(self)
      set_line(self, self.history[new_pos] or "")
      self.history_pos, self.pos, self.scroll = new_pos, #self.line, 0
      uncomplete(self)
      redraw(self)
    end
  end
end

local bindings = require "metis.input.keybinding".create {
  ["char"] = function(char, self) insert_line(self, char) end,

  ["enter"] = function(self)
    if self.forever then return end
    reset(self)
    self.running = false
  end,
  ["tab"] = accept_completion,
  ["C-d"] = function(self)
    if self.forever then return end

    reset(self)
    self.line = nil
    self.pos = 0
    self.running = false
  end,

  -- Text movement.
  ["right"] = move_right, ["C-f"] = move_right,
  ["left"] = move_to(left), ["C-b"] = move_to(left),
  ["C-right"] = move_to(next_word), ["M-f"] = move_to(next_word),
  ["C-left"] = move_to(prev_word), ["M-b"] = move_to(prev_word),
  ["home"] = move_to(start), ["C-a"] = move_to(start),
  ["end"] = move_to(finish), ["C-e"] = move_to(finish),

  -- Transpose a character
  ["C-t"] = function(self)
    local line, prev, cur = self.line
    if self.pos == #line then prev, cur = self.pos - 1, self.pos
    elseif self.pos == 0 then prev, cur = 1, 2
    else prev, cur = self.pos, self.pos + 1
    end

    set_line(self, line:sub(1, prev - 1) .. line:sub(cur, cur) .. line:sub(prev, prev) .. line:sub(cur + 1))
    self.pos = math.min(#self.line, cur)
    reset(self)
  end,
  ["M-u"] = on_word(string.upper),
  ["M-l"] = on_word(string.lower),
  ["M-c"] = on_word(function(s) return s:sub(1, 1):upper() .. s:sub(2):lower() end),

  ["backspace"] = function(self)
    if self.pos <= 0 then return end

    clear(self)
    set_line(self, self.line:sub(1, self.pos - 1) .. self.line:sub(self.pos + 1))
    self.pos = self.pos - 1
    if self.scroll > 0 then self.scroll = self.scroll - 1 end

    recomplete(self)
    redraw(self)
  end,
  ["delete"] = function(self)
    if self.pos >= #self.line then return end

    clear(self)
    set_line(self, self.line:sub(1, self.pos) .. self.line:sub(self.pos + 2))
    recomplete(self)
    redraw(self)
  end,

  ["C-u"] = kill_before(start),
  ["C-w"] = kill_before(prev_word),
  ["C-k"] = kill_after(finish),
  ["M-d"] = kill_after(next_word),
  ["C-y"] = function(self)
    if not self.last_killed then return end
    insert_line(self, self.last_killed)
  end,

  ["up"] = adjust_completion(-1),
  ["down"] = adjust_completion(1),
}

local function handle_event(self, event, ...)
  if event == "paste" then
    insert_line(self, ...)
  elseif event == "key" or event == "key_up" or event == "char" then
    bindings[event](bindings, ..., self)
  elseif event == "mouse_click" or event == "mouse_drag" and ... == 1 then
    local _, cy = term.getCursorPos()
    local _, x, y = ...
    if y ~= cy then return end

    -- We first clamp the x position with in the start and end points
    -- to ensure we don't scroll beyond the visible region.
    x = math.clamp(x, self.start_x, self.width)

    -- Then ensure we don't scroll beyond the current line
    self.pos = math.clamp(self.scroll + x - self.start_x, 0, #self.line)
    redraw(self)
  elseif event == "term_resize" then
    self.width = term.getSize()
    redraw(self)
  end
end

--[[- The main prompt function. Instead of accepting multiple arguments,
@{read} accepts an options table, with the following fields:

 - `default`: The text that this prompt will start with.
 - `replace_char`: A character that will be written in place of each typed
   character. This may be used to mask the user's input, such as when writing
   passwords.
 - `forever`: Whether this prompt will run forever, meaning <kbd>RET</kbd> and
   <kbd>C-d</kbd> have no effect. This should be used along with the `changed`
   function.
 - `changed`: A function called whenever the input is changed. This may be
   useful if you want to dynamically update your UI whenever text is written
   (for instance, if writing a search box).
 - `history`: A list of previous strings entered at this prompt. Items may be
   added to this list manually, or using @{insert_history}.
 - `complete`: A completion function. This accepts the current input string,
   and returns a list of suffixes that will be provided as completion
   candidates. The [`cc.complete`][cc.complete] module provides some utilities
   for working with these.
 - `complete_fg`: The foreground colour that completions will be written with.
   Defaults to light gray, and can be set to transparent by passing to `-1`.
 - `complete_bg`: The background colour that completions will be written with.
   Defaults to transparent.
 - `highlight`: A function to highlight the current input line. This will be
  given the current input line, and a position to start highlighting from. It
  must the end position of the token and its colour.

  See the example below for more details.

[cc.complete]: https://tweaked.cc/module/cc.completion.html

@tparam {
  default? = string,
  replace_char? = string,
  forever? = boolean,
  changed ?= function(value: string),
  history ?= { string... },
  complete? = function(line: string):{ string... },
  complete_fg? = number,
  complete_bg? = number,
  highlight = (function(line: string, pos: string):number),
} opts The options table, as documented above.
@treturn string|nil The entered text, or @{nil} if the prompt was closed with
<kbd>C-d</kbd>.
]]
local function read(opts)
  expect(1, opts, "table", "nil")
  if not opts then opts = {} end

  local line = field(opts, "default", "string", "nil") or ""
  local replace_char = field(opts, "replace_char", "string", "nil")
  local self = {
    line = line,
    pos = #line,
    scroll = 0,

    running = true,
    forever = field(opts, "forever", "boolean", "nil") or false,

    start_x = term.getCursorPos(),
    width = term.getSize(),

    changed = field(opts, "changed", "function", "nil") or void,

    replace_char = replace_char and replace_char:sub(1, 1),

    history = field(opts, "history", "table", "nil"),
    history_pos = nil,

    last_killed = nil,

    complete = field(opts, "complete", "function", "nil"),
    complete_fg = field(opts, "complete_fg", "number", "nil") or colours.lightGrey,
    complete_bg = field(opts, "complete_bg", "number", "nil") or -1,
    highlight = field(opts, "highlight", "function", "nil"),
  }

  term.setCursorBlink(true)
  recomplete(self)
  redraw(self)

  while self.running do handle_event(self, os.pullEvent()) end

  local _, cy = term.getCursorPos()
  term.setCursorBlink(false)
  term.setCursorPos(self.width + 1, cy)
  print()

  return self.line
end

--[[- Insert a string into the history table.

This is recommended over a simple @{table.insert}, as it ensures that duplicate
or blank strings are not added.

@tparam { string... } history The history of previous inputs.
@tparam string str The new input to add.
@treturn boolean If the history table was changed.
]]
local function insert_history(history, str)
  expect(1, history, "table")
  expect(2, str, "string")

  if str:find("%S") and history[#history] ~= str then
    history[#history + 1] = str
    return true
  else
    return false
  end
end

return {
  read = read,
  insert_history = insert_history,
}
