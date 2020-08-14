local empty_stub = require "test_helpers".empty_stub

describe("metis.input.keybinding", function()
  local keybinding = require "metis.input.keybinding"

  it("processes char", function()
    local char = empty_stub(stub)
    local kb = keybinding.create { char = char.value }

    kb:char("a")
    kb:char("b")
    kb:char("c")

    expect(char):called(3)
    expect(char):called_with("a")
    expect(char):called_with("b")
    expect(char):called_with("c")
  end)

  it("processes chars with alt-keys", function()
    local char, mx = empty_stub(stub), empty_stub(stub)
    local kb = keybinding.create {
      char = char.value,
      ["M-x"] = mx.value,
    }

    kb:char("x")
    expect(char):called(1)

    kb:key(keys.leftAlt)
    kb:char("x")
    expect(char):called(1)

    kb:char("c")
    expect(char):called(2)
    expect(char):called_with("c")
  end)

  it("fires key events", function()
    local x, mx, cmx, cx = empty_stub(stub), empty_stub(stub), empty_stub(stub), empty_stub(stub)
    local kb = keybinding.create {
      ["x"] = x.value,
      ["M-x"] = mx.value,
      ["C-M-x"] = cmx.value,
      ["C-x"] = cx.value,
    }

    local function state(n_x, n_mx, n_cmx, n_cx)
      expect(x):called(n_x)
      expect(mx):called(n_mx)
      expect(cmx):called(n_cmx)
      expect(cx):called(n_cx)
    end

    kb:key(keys.x) state(1, 0, 0, 0)
    kb:key(keys.leftAlt) state(1, 0, 0, 0)
    kb:key(keys.x) state(1, 1, 0, 0)
    kb:key(keys.x) state(1, 2, 0, 0)

    kb:key(keys.leftCtrl)
    kb:key(keys.x)
    state(1, 2, 1, 0)

    kb:key_up(keys.leftAlt)
    kb:key(keys.x)
    state(1, 2, 1, 1)

    kb:key_up(keys.leftCtrl)
    kb:key(keys.x)
    state(2, 2, 1, 1)
  end)
end)
