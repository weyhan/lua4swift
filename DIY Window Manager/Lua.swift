import Foundation

struct Lua {
    
    let L = luaL_newstate()
    
    private typealias CFunction = (COpaquePointer) -> Int32
    typealias Function = (Lua) -> Int
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: CFunction = { L in Int32(fn(self)) }
        lua_pushcclosure(L, SDLuaTrampoline(f), Int32(upvalues))
    }
    
    func setGlobal(name: String) {
        lua_setglobal(L, (name as NSString).UTF8String)
    }
    
    func loadString(str: String) {
        luaL_loadstring(L, (str as NSString).UTF8String)
    }
    
    func pushNumber(n: Double) {
        lua_pushnumber(L, n)
    }
    
    func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
    func toNumber(position: Int) -> Double? {
        var isNumber: Int32 = 0
        let n = lua_tonumberx(L, Int32(position), &isNumber)
        if isNumber == 0 { return nil }
        return n
    }
    
}
