local capture = require "test_helpers".capture

describe("metis.argparse", function()
  local argparse = require "metis.argparse"

  it("displays usage", function()
    local spec = argparse.create()
    spec:add({ "--test", "-t" }, { doc = "Does something"})
    spec:add("another")

    local result = capture(stub, pcall, spec.parse, spec, "--help")
    expect(result.combined):same(table.concat({
      "USAGE\n",
      " --test,-t    Does something\n",
      " ANOTHER      \n",
      " -h,--help,-? Show this help message\n"
    }))
  end)
end)
