local testing = require "test_helpers".testing
describe("metis.string", function()
  local string = require "metis.string"

  testing(_ENV, "string.starts_with", string.starts_with, function(check)
    check(true, "foobar", "foo")
    check(false, "foobar", "fos")
    check(false, ">foobar", "foo")
    check(false, "foo", "foobar")
  end)

  testing(_ENV, "string.ends_with", string.ends_with, function(check)
    check(true, "foobar", "bar")
    check(false, "foobar", "baz")
    check(false, "foobar<", "bar")
    check(false, "bar", "foobar")
  end)

  testing(_ENV, "string.split", string.split, function(check)
    describe("empty strings", function()
      check({ "" }, "", "%-")
      check({ "", "" }, "-", "%-")
      check({ "", "", "", "" }, "---", "%-")
      check({ "", "a" }, "-a", "%-")
      check({ "a", "" }, "a-", "%-")
    end)

    describe("patterns", function()
      check({ "a", "bcd", "ef" }, "a.bcd      ef", "%W+")
    end)

    describe("plain", function()
      check({ "a", "bcd", "ef" }, "a-bcd-ef", "-", true)
    end)

    describe("limit", function()
      check({ "foo", "bar", "baz-qux-quyux" }, "foo-bar-baz-qux-quyux", "-", true, 3)
      check({ "foo", "bar", "baz" }, "foo-bar-baz", "-", true, 5)
      check({ "foo-bar-baz" }, "foo-bar-baz", "-", true, 1)
      check({ "foo-bar-baz" }, "foo-bar-baz", "-", true, 1)
    end)
  end)

  testing(_ENV, "string.escape_pattern", string.escape_pattern, function(check)
    check("%^%$%(%)%%%.%[%]%*%+%-%?%z", "^$()%.[]*+-?\0")
  end)
end)
