import Foundation

class API {
    
    final class Hotkey: LuaLibrary {
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
        
        func enable(L: Lua) -> [LuaValue] {
            hotkey.enable()
            return []
        }
        
        func disable(L: Lua) -> [LuaValue] {
            hotkey.disable()
            return []
        }
        
        class func bind(L: Lua) -> [LuaValue] {
            let key = L.getString(1)!
            let mods = L.getTable(2)!
            L.pushFromStack(3)
            
            let modStrings = mods.map{$1 as? String}.filter{$0 != nil}.map{$0!}
            
            let hotkey = DIY_Window_Manager.Hotkey(key: key, mods: modStrings, downFn: {}, upFn: nil)
            hotkey.enable()
            
            let i = L.ref(Lua.RegistryIndex)
            L.pushMetaUserdata(Hotkey(fn: i, hotkey: hotkey))
            
            return []
        }
        
        func cleanup(L: Lua) {
            hotkey.disable()
            L.unref(Lua.RegistryIndex, fn)
        }
        
        func equals(other: Hotkey) -> Bool {
            return fn == other.fn
        }
        
        class func classMethods() -> [(String, [Lua.Kind], Lua -> [LuaValue])] {
            return [
                ("bind", [.String, .Table, .Function, .None], Hotkey.bind),
            ]
        }
        
        class func instanceMethods() -> [(String, [Lua.Kind], Hotkey -> Lua -> [LuaValue])] {
            return [
                ("enable", [.None], Hotkey.enable),
                ("disable", [.None], Hotkey.enable),
            ]
        }
        
        class func metaMethods() -> [LuaMetaMethod<Hotkey>] {
            return [
                .GC(Hotkey.cleanup),
                .EQ(Hotkey.equals),
            ]
        }
    }
    
}
