import Foundation

class API {
    
    final class Hotkey: LuaLibrary {
        let fn: Int
        let hotkey: Carbon.Hotkey
        
        class var metatableName: String { return "Hotkey" }
        
        func pushValue(L: Lua) {
            L.pushUserdata(self)
        }
        
        class func fromLua(L: Lua, at position: Int) -> Hotkey? {
            return L.getUserdata(position) as? Hotkey
        }
        
        init(fn: Int, hotkey: Carbon.Hotkey) {
            self.fn = fn
            self.hotkey = hotkey
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
            return []
            
//            let key = String.fromLua(L, at: 1)!
//            let mods = Lua.TableBox.fromLua(L, at: 2)!.t
//            let modStrings = mods.map{$1 as? String}.filter{$0 != nil}.map{$0!}
//            
//            L.pushFromStack(3)
//            let i = L.ref(Lua.RegistryIndex)
//            
//            let downFn: Carbon.Hotkey.Callback = {
//                L.rawGet(tablePosition: Lua.RegistryIndex, index: i)
//                L.call(arguments: 1, returnValues: 0)
//            }
//            
//            let hotkey = Carbon.Hotkey(key: key, mods: modStrings, downFn: downFn, upFn: nil)
//            hotkey.enable()
//            
//            return [Hotkey(fn: i, hotkey: hotkey)]
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
