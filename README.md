# DIY Window Manager

* Current version: 0.1
* Requires: OS X 10.10 or higher

## What can it do?

Currently:

- Crash
- Eat your computer
- Accidentally make you lose all your money somehow
- Eat all your food
- Make carnivorous dinosaurs come back alive at the worst possible time in the middle of a crowded city
- Probably cause a singularity?
- Accidentally fix the singularity by trying to use an invalid C pointer

## What's it do?

This app gives you simple Lua APIs that let you interact with your
system. The main classes are Window, App, Screen, Hotkey, and Event.

Since it uses Lua, it's naturally geared towards programmers who want
to customize their system very specifically.

That said, it also provides a higher-level API layer to give you easy
access to common layouts.

## Extensible

The source code is designed to be very easy to extend, so that anyone
with a little knowledge of the underlying system APIs can easily add
features.

If you're interested in adding features and sending them in a pull
request, see [Contributing.md](Contributing.md).
