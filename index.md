# [metis][github]

A collection of useful modules for ComputerCraft/CC: Tweaked. There's not much rhyme or reason to this really, so feel
free to PR useful libraries you might have.

## Usage
Paste the following code block on the top of your program, then feel free to require any of the documented modules.

```lua
local modules = {
  ["metis.argparse"] = "src/metis/argparse.lua",
  ["metis.async"] = "src/metis/async.lua",
  ["metis.crypto.sha1"] = "src/metis/crypto/sha1.lua",
  ["metis.fs"] = "src/metis/fs.lua",
  ["metis.input.keybinding"] = "src/metis/input/keybinding.lua",
  ["metis.input.readline"] = "src/metis/input/readline.lua",
  ["metis.math"] = "src/metis/math.lua",
  ["metis.string"] = "src/metis/string.lua",
  ["metis.string.fuzzy"] = "src/metis/string/fuzzy.lua",
  ["metis.timer"] = "src/metis/timer.lua",
}
package.loaders[#package.loaders + 1] = function(name)
  local path = modules[name]
  if not path then return nil, "not a metis module" end

  local local_path = "/.cache/metis/8ae2034c0d17a67bcc8b307ca3e042feb62c5938/" .. path
  if not fs.exists(local_path) then
    local url = "https://raw.githubusercontent.com/SquidDev-CC/metis/8ae2034c0d17a67bcc8b307ca3e042feb62c5938/" .. path
    local request, err = http.get(url)
    if not request then return nil, "Cannot download " .. url .. ": " .. err end

    local out = fs.open(local_path, "w")
    out.write(request.readAll())
    out.close()

    request.close()
  end


  local fn, err = loadfile(local_path, nil, _ENV)
  if fn then return fn, local_path else return nil, err end
end
```

For other ways of using metis, see the [github repository][github].


[github]: https://github.com/SquidDev-CC/metis "metis on GitHub"
