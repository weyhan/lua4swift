#
# Be sure to run `pod lib lint lua4swift.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'lua4swift'
  s.version          = '1.0.0'
  s.summary          = 'High-level (convenient) Lua bindings for Swift'

  s.description      = <<-DESC
  High-level (convenient) Lua bindings for Swift

  What do you mean by "convenient"?

  It's meant to be used to add extensibility to your OS X application. The idea is, you already wrote an app and just want to make it extensible in Lua, so you just throw this library in, and start wrapping your app's internal types and functions to work with Lua, and start running your user's Lua code.

  What do you mean by "high-level"?

  This library doesn't let you use the traditional "Lua stack". Instead, you operate with Swift values:

  When you create a Lua function, you really give it a Swift function which this library wraps up. That function takes an array of values which you then extract and use. When you're done, you return an array of values. When you want to create values, you don't push them onto a stack, you create them using methods on your VirtualMachine instance.

  These values are either of types common to both Lua and Swift, such as String and Boolean, or a Swift wrapper around a Lua type, such as Function and Number. This means returning values from your custom Lua functions can be as natural as return ["foo", "bar"].

  Lua's table type is wrapped using a class that has Swift's subscript notation, so you can use it like t[3] = "foo" or t["foo"] = myLuaFunction. This also has the added benefit of giving us a more natural and consistent way of accessing Lua's "globals" and "registry", which are both methods of type () -> Lua.Table on a VirtualMachine instance.

  Because of all this, this library makes some trade-offs that make it not as optimal with speed and memory as it could have been.

  What do you mean by "Swift"?

  (ಠ_ಠ)

  What do you mean by "bindings"?

  Like, it wraps Lua's C API so you can use Lua from Swift. That kind of bindings. Not the other kind. And not the other other kind. Binding has too many meanings. Maybe we should like, use more better words when saying about stuff?
                       DESC

  s.homepage         = 'https://github.com/sdegutis/lua4swift'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Steven Degutis' => 'sdegutis@users.noreply.github.com' }
  s.source           = { :git => 'https://github.com/sdegutis/lua4swift.git', :tag => s.version.to_s }
  s.swift_version    = '4.0'
  s.module_name = 'Lua'

  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.9'

  s.source_files = 'Lua/*.{swift}', 'LuaSource/*.{c,h,m}'

end
