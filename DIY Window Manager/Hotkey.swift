import Foundation
import Graphite
import Lua

final class Hotkey: Lua.CustomType {
    
    let fn: Lua.Function
    let hotkey: Graphite.Hotkey
    
    class func metatableName() -> String { return "Hotkey" }
    
    init(fn: Lua.Function, hotkey: Graphite.Hotkey) {
        self.fn = fn
        self.hotkey = hotkey
    }
    
    func enable(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        hotkey.enable()
        return .Nothing
    }
    
    func disable(vm: Lua.VirtualMachine, args: [Lua.Value]) -> SwiftReturnValue {
        hotkey.disable()
        return .Nothing
    }
    
    class func bind(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        let key = args[0] as String
        let mods = args[1] as Lua.Table // TODO: should be a sequence of Strings
        let downFn = args[2] as Lua.Function
        
        let modStrings = ["cmd", "shift"] // TODO: lol
        
        let downSwiftFn: Graphite.Hotkey.Callback = { [weak vm] in
            downFn.call([])
            return
        }
        
        let hotkey = Graphite.Hotkey(key: key, mods: modStrings, downFn: downSwiftFn, upFn: nil)
        switch hotkey.enable() {
        case let .Error(error):
            return .Error(error)
        case .Success:
            return .Value(vm.createUserdata(Hotkey(fn: downFn, hotkey: hotkey)))
        }
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("bind", [String.self, Lua.Table.self, Lua.Function.self], Hotkey.bind),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Hotkey -> (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("enable", [], Hotkey.enable),
            ("disable", [], Hotkey.disable),
        ]
    }
    
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<Hotkey>) {
        metaMethods.eq = { $0.fn == $1.fn }
        metaMethods.gc = { this, L in
            println("gone hotkey!")
            this.hotkey.disable()
        }
    }
    
}
