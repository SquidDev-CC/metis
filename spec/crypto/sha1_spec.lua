describe("metis.crypto.sha1", function()
  local sha1 = require "metis.crypto.sha1"

  describe("passes test vectors", function()
    local h = io.open("/spec-data/Sha1ShortMsg.rsp")
    while true do
      local line = h:read("*l")
      if not line then break end

      local len = line:match("^Len = (%w+)$")
      if len then
        local len = tonumber(len)
        local msg = h:read("*l"):match("^Msg = (%w+)$")
        local output = h:read("*l"):match("^MD = (%w+)$")

        it(("len %d"):format(len), function()
          local input = ""
          for i = 1, #msg, 2 do input = input .. string.char(tonumber(msg:sub(i, i + 1), 16)) end
          input = input:sub(1, len / 8)

          expect(sha1(input)):eq(output)
        end)
      end
    end

    h:close()
  end)
end)
