--[[- Calculate the SHA1 hash for some text.

SHA1 has been [broken] for several years now, and so should not be treated as
secure. However, it is often a useful (and efficient) way to compute a checksum
of a value.

[broken]: https://shattered.io/

@usage Hash the string "Hello, world!"

    local sha1 = require "metis.crypto.sha1"
    print(sha1("Hello, world!"))
    -- 943a702d06f34599aee1f8da8ef9f7296031d699

@usage Hash a file without reading it all into memory.

    local sha1 = require "metis.crypto.sha1"
    local h = fs.open("rom/startup.lua", "r")
    local sha = sha1.create()
    while true do
      local block = h.read(2048)
      if not block then return end
      sha:append(block)
    end
    print(tostring(sha))
]]

--[[
  MIT LICENSE

  Copyright (c) 2013 Enrique García Cota + Eike Decker + Jeffrey Friedl

  Permission is hereby granted, free of charge, to any person obtaining a
  copy of this software and associated documentation files (the
  "Software"), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:

  The above copyright notice and this permission notice shall be included
  in all copies or substantial portions of the Software.

  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS
  OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
]]

-- local storing of global functions (minor speedup)
local expect = require "cc.expect".expect
local _, modf = math.floor, math.modf
local char, format, rep = string.char, string.format, string.rep
local band, bor, bxor, bnot = bit32.band, bit32.bor, bit32.bxor, bit32.bnot

-- merge 4 bytes to an 32 bit word
local function bytes_to_w32(a, b, c, d) return a * 0x1000000 + b * 0x10000 + c * 0x100 + d end

-- shift the bits of a 32 bit word. Don't use negative values for "bits"
local function w32_rot(bits, a)
  local b2 = 2 ^ (32 - bits)
  local a, b = modf(a / b2)
  return a + b * b2 * 2 ^ bits
end

--- adding 2 32bit numbers, cutting off the remainder on 33th bit
local function w32_add(a, b) return (a + b) % 4294967296 end

--- adding n 32bit numbers, cutting off the remainder (again)
local function w32_add_n(a, ...)
  for i = 1, select('#', ...) do
    a = (a + select(i, ...)) % 4294967296
  end
  return a
end

-- converting the number to a hexadecimal string
local function w32_to_hexstring(w) return format("%08x", w) end

--- Perform a single round of hashing.
local function chunk(msg, start, W, H0, H1, H2, H3, H4)
  for t = 0, 15 do
    W[t] = bytes_to_w32(msg:byte(start, start + 3))
    start = start + 4
  end

  -- build W[16] through W[79]
  for t = 16, 79 do
    -- For t = 16 to 79 let Wt = S1(Wt-3 XOR Wt-8 XOR Wt-14 XOR Wt-16).
    W[t] = w32_rot(1, bxor(W[t - 3], W[t - 8], W[t - 14], W[t - 16]))
  end

  local A, B, C, D, E = H0, H1, H2, H3, H4

  local f, K
  for t = 0, 79 do
    if t <= 19 then
      -- (B AND C) OR ((NOT B) AND D)
      f = bor(band(B, C), band(bnot(B), D))
      K = 0x5A827999
    elseif t <= 39 then
      -- B XOR C XOR D
      f = bxor(B, C, D)
      K = 0x6ED9EBA1
    elseif t <= 59 then
      -- (B AND C) OR (B AND D) OR (C AND D)
      f = bor(band(B, C), band(B, D), band(C, D))
      K = 0x8F1BBCDC
    else
      -- B XOR C XOR D
      f = bxor(B, C, D)
      K = 0xCA62C1D6
    end

    -- TEMP = S5(A) + ft(B,C,D) + E + Wt + Kt;
    A, B, C, D, E = w32_add_n(w32_rot(5, A), f, E, W[t], K), A, w32_rot(30, B), C, D
  end

  -- Let H0 = H0 + A, H1 = H1 + B, H2 = H2 + C, H3 = H3 + D, H4 = H4 + E.
  return w32_add(H0, A), w32_add(H1, B), w32_add(H2, C), w32_add(H3, D), w32_add(H4, E)
end

--[[- A "work in progress" hash, created with @{create}.

The hash input may be extended with @{Hash:append} and the final string computed
with @{tostring}.

@type Hash
]]
local Hash = {
  __tostring = function(self) return self.__tostring() end,
  __index = {
    --- Append a string to this hash buffer.
    --
    -- Repeated calls to this function are equivalent to concatination:
    -- `s:append(a) s:append(b)` is equivalent to `s:append(a .. b)`. The former
    -- should be preferred, as it is (generally) more efficient.
    --
    -- @tparam Hash self The current hash object.
    -- @tparam string str The string to hash.
    append = function(self, str) return self.__append(str) end,
  },
}

--[[- Construct a new hash builder, to generate a SHA1 hash incrementally.

The `sha1` module may be called as a function directly (see the module
description) to compute the hash. However, in some circumstances it may be
better to build a hash incrementally.

For instance, instead of reading a file in one go, one may read it in chunks and
hash each chunk separately.

@treturn Hash The hash builder.
]]
local function create()
  local H0, H1, H2, H3, H4 = 0x67452301, 0xEFCDAB89, 0x98BADCFE, 0x10325476, 0xC3D2E1F0
  local W = { }
  local msg, msg_len = "", 0

  local function append(extra)
    expect(1, extra, "string")

    msg_len = msg_len + #extra
    msg = msg .. extra

    if #msg < 64 then return end

    for i = 1, #msg + 1 - 64, 64 do
      H0, H1, H2, H3, H4 = chunk(msg, i, W, H0, H1, H2, H3, H4)
    end
    msg = msg:sub(#msg - #msg % 64 + 1)
  end

  --- Convert this string
  local function tostring()
    local msg_len_in_bits = msg_len * 8

    local first_append = char(0x80) -- append a '1' bit plus seven '0' bits
    local non_zero_message_bytes = msg_len + 1 + 8 -- the +1 is the appended bit 1, the +8 are for the final appended length
    local current_mod = non_zero_message_bytes % 64
    local second_append = current_mod > 0 and rep(char(0), 64 - current_mod) or ""

    -- now to append the length as a 64-bit number.
    local B1, R1 = modf(msg_len_in_bits	/ 0x01000000)
    local B2, R2 = modf(0x01000000 * R1 / 0x00010000)
    local B3, R3 = modf(0x00010000 * R2 / 0x00000100)
    local B4     = 0x00000100 * R3

    local L64 = char(0) .. char(0) .. char(0) .. char(0) -- high 32 bits
          .. char(B1) .. char(B2) .. char(B3) .. char(B4) --	low 32 bits

    local msg = msg .. first_append .. second_append .. L64
    local H0, H1, H2, H3, H4 = H0, H1, H2, H3, H4
    for i = 1, #msg + 1 - 64, 64 do
      H0, H1, H2, H3, H4 = chunk(msg, i, W, H0, H1, H2, H3, H4)
    end

    local f = w32_to_hexstring
    return f(H0) .. f(H1) .. f(H2) .. f(H3) .. f(H4)
  end

  return setmetatable({ __append = append, __tostring = tostring }, Hash)
end


--[[- Calculate the SHA1 hash for some text.

@tparam string msg The message to hash.
@treturn string The hashed value.
]]
local function sha1(msg)
  expect(1, msg, "string")

  local h = create()
  h:append(msg)
  return tostring(h)
end

local M = { create = create }
setmetatable(M, { __call = function(_, ...) return sha1(...) end })
return M
