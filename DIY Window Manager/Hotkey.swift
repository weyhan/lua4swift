import Foundation
import Graphite
import Lua

extension Graphite.Hotkey: Lua.CustomType {
    public class func metatableName() -> String { return "Hotkey" }
}

func hotkeyLib(vm: Lua.VirtualMachine) -> Lua.Library<Graphite.Hotkey> {
    return vm.createLibrary { [unowned vm] lib in
        
        lib["bind"] = vm.createFunction([String.arg, Table.arg, Function.arg]) { args in
            let (key, modStrings: [String], downFn) = (args.string, args.table.asSequence(), args.function)
            
            let downSwiftFn: Graphite.Hotkey.Callback = {
                switch downFn.call([]) {
                case let .Error(e):
                    println(e)
                case let .Values(v):
                    println(v)
                }
                return
            }
            
            let hotkey: Graphite.Hotkey = Graphite.Hotkey(key: key, mods: modStrings, downFn: downSwiftFn, upFn: nil)
            switch hotkey.enable() {
            case let .Error(error):
                return .Error(error)
            case .Success:
                return .Value(vm.createUserdata(hotkey) as Lua.Userdata)
            }
        }
        
        lib["enable"] = lib.createMethod([]) { hotkey, args in
            hotkey.enable()
            return .Nothing
        }
        
        lib["disable"] = lib.createMethod([]) { hotkey, args in
            hotkey.disable()
            return .Nothing
        }
        
        lib.gc = { hotkey in
            hotkey.disable()
        }
        
    }
}
