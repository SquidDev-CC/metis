# metis

A collection of useful modules for ComputerCraft/CC: Tweaked. There's not much rhyme or reason to this really, so feel
free to PR useful libraries you might have.

## Tips for developing
 - Assuming you've got CCEmuX installed, you can start it in the current directory by running `bin/ccemux.lua`.
 - _Within CC_ (or an emulator), `bin/mcfly.lua` will run the (rather lacklustre) test-suite.

## Using metis within your own projects
There's two options here:

 1. Copy the files you need into your project directory.
 2. Clone this repository and run the `bin/mk-loader.lua` script (outside of CC). This'll print out a snippet which
    should be copied to the top of your program.

Then just `require` files as normal. For instance, `require "metis.timer"`.
