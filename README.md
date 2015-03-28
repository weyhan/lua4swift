# lua4swift

*High-level (convenient) Lua bindings for Swift*

* **Version**: 1.0

## What do you mean by "convenient"?

It's meant to be used to add extensibility to your OS X application. The idea is, you already wrote an app and just want to make it extensible in Lua, so you just throw this library in, and start wrapping your app's internal types and functions to work with Lua, and start running your user's Lua code.

## What do you mean by "high-level"?

This library doesn't let you use the traditional "Lua stack". Instead, you operate with Swift values:

When you create a Lua function, you really give it a Swift function which this library wraps up. That function takes an array of values which you then extract and use. When you're done, you return an array of values. When you want to create values, you don't push them onto a stack, you create them using methods on your `VirtualMachine` instance.

These values are either of types common to both Lua and Swift, such as String and Boolean, or a Swift wrapper around a Lua type, such as Function and Number. This means returning values from your custom Lua functions can be as natural as `return ["foo", "bar"]`.

Lua's `table` type is wrapped using a class that has Swift's subscript notation, so you can use it like `t[3] = "foo"` or `t["foo"] = myLuaFunction`. This also has the added benefit of giving us a more natural and consistent way of accessing Lua's "globals" and "registry", which are both methods of type `() -> Lua.Table` on a `VirtualMachine` instance.

Because of all this, this library makes some trade-offs that make it not as optimal with speed and memory as it could have been.

## What do you mean by "Swift"?

(ಠ_ಠ)

## What do you mean by "bindings"?

Like, it wraps Lua's C API so you can use Lua from Swift. That kind of bindings. Not the other kind. And not the other other kind. Binding has too many meanings. Maybe we should like, use more better words when saying about stuff?

## Show us an example already!

Okay fine.

Here's a port of the function in Roberto's Lua book to split a string by a string delimiter:

~~~swift
let vm = Lua.VirtualMachine()

let stringxLib = vm.createTable()

stringxLib["split"] = vm.createFunction([String.arg, String.arg]) { args in
    let (subject, separator) = (args.string, args.string)
    let fragments = subject.componentsSeparatedByString(separator)

    let results = vm.createTable()
    for (i, fragment) in enumerate(fragments) {
        results[i+1] = fragment
    }
    return .Value(results)
}

vm.globals["stringx"] = stringxLib
~~~

Given this, you could do this in Lua:

~~~lua
stringx.split('hello world', ' ')  -- returns {"hello", "world"}
~~~

## License

> Released under MIT license.
>
> Copyright (c) 2015 Steven Degutis
>
> Permission is hereby granted, free of charge, to any person obtaining a copy
> of this software and associated documentation files (the "Software"), to deal
> in the Software without restriction, including without limitation the rights
> to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
> copies of the Software, and to permit persons to whom the Software is
> furnished to do so, subject to the following conditions:
>
> The above copyright notice and this permission notice shall be included in
> all copies or substantial portions of the Software.
>
> THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
> IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
> FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
> AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
> LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
> OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
> THE SOFTWARE.
