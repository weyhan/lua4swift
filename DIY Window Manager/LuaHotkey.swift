import Foundation


class LuaHotkey: LuaMetatableOwner {
    let fn: Int
    let hotkey: Hotkey
    
    class var metatableName: String { return "Hotkey" }
    
    init(fn: Int, hotkey: Hotkey) {
        self.fn = fn
        self.hotkey = hotkey
    }
    
    func call(L: Lua) {
        L.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
        L.call(arguments: 1, returnValues: 0)
    }
    
    class func pushLibrary(L: Lua) {
        L.pushTable()
        
        L.pushMetatable("Hotkey") {
            L.pushMethod("__eq") { L in
                L.checkArgs(.Userdata("Hotkey"), .Userdata("Hotkey"), .None)
                let a: LuaHotkey = L.getUserdata(1)!
                let b: LuaHotkey = L.getUserdata(2)!
                L.pushBool(a.fn == b.fn)
                return 1
            }
            
            L.pushMetaMethod(LuaMetaMethod.GC({ (L, o: LuaHotkey) in
                o.hotkey.disable()
                L.unref(Lua.RegistryIndex, o.fn)
            }))
        }
        
        L.pushMethod("bind") { L in
            L.checkArgs(.String, .Table, .Function, .None)
            let key = L.getString(1)!
            let mods = L.getTable(2)!
            L.pushFromStack(3)
            
            var modStrings = [String]()
            for (_, mod) in mods {
                switch mod {
                case let .String(s): modStrings.append(s);
                default: break
                }
            }
            
            let hotkey = Hotkey(key: key, mods: modStrings, downFn: {}, upFn: nil)
            hotkey.enable()
            
            let i = L.ref(Lua.RegistryIndex)
            L.pushUserdata(LuaHotkey(fn: i, hotkey: hotkey))
            L.setMetatable("Hotkey")
            
            return 1
        }
        
        // Hotkey.__index = Hotkey
        L.pushFromStack(-1)
        L.setField("__index", table: -2)
    }
}
