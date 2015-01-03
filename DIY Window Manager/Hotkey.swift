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
    
//    class func bind(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.ReturnValue {
//        let key = String(fromLua: vm, at: 1)!
//        let modStrings = Lua.SequentialTable<String>(fromLua: vm, at: 2)!.elements
//        
//        vm.pushFromStack(3)
//        let i = vm.ref(Lua.RegistryIndex)
//        
//        let downFn: Graphite.Hotkey.Callback = { [weak vm] in
//            vm?.rawGet(tablePosition: Lua.RegistryIndex, index: i)
//            vm?.call(arguments: 0, returnValues: 0)
//        }
//        
//        let hotkey = Graphite.Hotkey(key: key, mods: modStrings, downFn: downFn, upFn: nil)
//        switch hotkey.enable() {
//        case let .Error(error):
//            return .Error(error)
//        case .Success:
//            return .Value(Lua.UserdataBox(Hotkey(fn: i, hotkey: hotkey)))
//        }
//    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
//            ("bind", [String.arg(), Lua.SequentialTable<String>.arg(), Lua.FunctionBox.arg()], Hotkey.bind),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Hotkey -> (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("enable", [], Hotkey.enable),
//            ("disable", [], Hotkey.disable),
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
