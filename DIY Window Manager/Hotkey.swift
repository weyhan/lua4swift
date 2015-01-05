import Foundation
import Graphite
import Lua

struct Hotkey: Lua.CustomType {
    
    let fn: Lua.Function
    let hotkey: Graphite.Hotkey
    
    static func metatableName() -> String { return "Hotkey" }
    
    func enable(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        hotkey.enable()
        return .Nothing
    }
    
    func disable(vm: Lua.VirtualMachine, args: [Lua.Value]) -> SwiftReturnValue {
        hotkey.disable()
        return .Nothing
    }
    
    static func bind(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        if let err = vm.checkTypes(args, [.String, .Table, .Function]) { return .Error(err) }
        
        let key = args[0] as String
        let modStrings: [String] = (args[1] as Lua.Table).asSequence()
        let downFn = args[2] as Lua.Function
        
        let downSwiftFn: Graphite.Hotkey.Callback = { [weak vm] in
            switch downFn.call([]) {
            case let .Error(e):
                println(e)
            case let .Values(v):
                println(v)
            }
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
    
    static func classMethods() -> [(String, (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("bind", Hotkey.bind),
        ]
    }
    
    static func instanceMethods() -> [(String, Hotkey -> (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("enable", Hotkey.enable),
            ("disable", Hotkey.disable),
        ]
    }
    
    static func setMetaMethods(inout metaMethods: Lua.MetaMethods<Hotkey>) {
        metaMethods.eq = { $0.fn == $1.fn }
        metaMethods.gc = { this, L in
            println("gone hotkey!")
            this.hotkey.disable()
        }
    }
    
}
