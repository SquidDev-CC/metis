---
module: [kind=notes] usage
---

# Using metis in your own projects

The simplest way to use metis is just to copy and paste individual functions or
modules into your own project. However, there's a couple of other ways too:

## Custom module loader:
Paste the following code block on the top of your program. Then just use
`require` to load any metis-specific modules.

```lua
%LOADER%
```

This registers a custom package loader which downloads (and caches) modules
straight from GitHub.

## Packman

1. [Install Packman][packman]: `pastebin run 4zyreNZy`
2. Open a Lua REPL (run `lua` in the shell) and run the following code:
   ```lua
   io.open("/etc/custom-repolist", "a"):write("metis https://metis.madefor.cc/packlist"):close()
   ```
   Now exit the REPL with `exit()`.
3. Update repositories: `packman fetch`.
4. Install metis: `packman install metis/metis-full`.


[packman]: http://www.computercraft.info/forums2/index.php?/topic/22268-packman-a-package-management-tool/ "Packman - A package management tool"
