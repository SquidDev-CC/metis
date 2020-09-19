describe("metis.string.fuzzy", function()
  local fuzzy = require"metis.string.fuzzy"

  it("returns nil on non-matches", function()
    expect(fuzzy("foo", "fooo")):eq(nil)
    expect(fuzzy("foo", "z")):eq(nil)
  end)

  it("works on empty patterns", function()
    expect(fuzzy("foo", "")):eq(-3)
  end)

  it("works on empty strings", function()
    expect(fuzzy("", "foo")):eq(nil)
  end)

  it("scores adjacent letters", function()
    expect(fuzzy("foo bar baz", "foo")):eq(10)
    expect(fuzzy("f oo bar baz", "foo")):eq(4)
  end)

  it("penalises non-leading letters", function()
    expect(fuzzy("foo bar baz", "oo ")):eq(7)
    expect(fuzzy("foo bar baz", "o b")):eq(4)
    expect(fuzzy("foo bar baz", "baz")):eq(1)
  end)
end)
