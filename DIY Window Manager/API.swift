import Foundation


class API {
    
    class Hotkey: LuaMetatableOwner {
        let fn: Int
        let hotkey: DIY_Window_Manager.Hotkey
        
        class var metatableName: String { return "Hotkey" }
        
        init(fn: Int, hotkey: DIY_Window_Manager.Hotkey) {
            self.fn = fn
            self.hotkey = hotkey
        }
        
        func call(L: Lua) {
            L.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
            L.call(arguments: 1, returnValues: 0)
        }
        
        class func pushLibrary(L: Lua) {
            L.pushTable()
            
            L.pushMetatable("Hotkey",
                .EQ({ (a: Hotkey, b: Hotkey) in
                    return a.fn == b.fn
                }),
                .GC({ (L, o: Hotkey) in
                    o.hotkey.disable()
                    L.unref(Lua.RegistryIndex, o.fn)
                })
            )
            L.setMetatable(-2)
            
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
                
                let hotkey = DIY_Window_Manager.Hotkey(key: key, mods: modStrings, downFn: {}, upFn: nil)
                hotkey.enable()
                
                let i = L.ref(Lua.RegistryIndex)
                L.pushMetaUserdata(Hotkey(fn: i, hotkey: hotkey))
                
                return 1
            }
            
            // Hotkey.__index = Hotkey
            L.pushFromStack(-1)
            L.setField("__index", table: -2)
        }
    }
    
}
