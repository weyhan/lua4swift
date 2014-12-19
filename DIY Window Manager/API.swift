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
            
            L.pushMetatable(
                .GC({ (o: Hotkey) in
                    o.hotkey.disable()
                    L.unref(Lua.RegistryIndex, o.fn)
                }),
                .EQ({ $0.fn == $1.fn })
            )
            L.setMetatable(-2)
            
            L.pushMethod("bind") {
                L.checkArgs(.String, .Table, .Function, .None)
                let key = L.getString(1)!
                let mods = L.getRawTable(2)!
                L.pushFromStack(3)
                
                let modStrings = mods.map{$1 as? String}.filter{$0 != nil}.map{$0!}
                
                let hotkey = DIY_Window_Manager.Hotkey(key: key, mods: modStrings, downFn: {}, upFn: nil)
                hotkey.enable()
                
                let i = L.ref(Lua.RegistryIndex)
                L.pushMetaUserdata(Hotkey(fn: i, hotkey: hotkey))
                
                return []
            }
            
            L.pushMethod("enable") {
                L.checkArgs(.Userdata(Hotkey.metatableName), .None)
                let hotkey: Hotkey = L.getUserdata(1)!
                hotkey.hotkey.enable()
                return []
            }
            
            // Hotkey.__index = Hotkey
            L.pushFromStack(-1)
            L.setField("__index", table: -2)
        }
    }
    
}
