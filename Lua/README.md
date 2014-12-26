# Lua

*Swift wrapper around Lua's C API*

Because there's just so much more you can do this way.

## Current status

I'm still thinking about the API. Nothing here is stable yet, though
it works pretty darn well. Lua.CustomType is pretty solid, but will be
improved once a few bugs in the Swift compiler are fixed.

## TODO

Figure out a way to wrap the stack in a pretty Swift-like API.

Ideas:

- Maybe a SwiftPosition type, representing an index?
- Or how about a Stack class that has all the stack methods?
- Idea #3: Come up with more ideas.
