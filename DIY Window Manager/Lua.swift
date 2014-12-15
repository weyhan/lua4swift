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
    
    func setField(name: String, table: Int) {
        lua_setfield(L, Int32(table), (name as NSString).UTF8String)
    }
    
    func newTable(sequenceCapacity: Int = 0, otherCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(otherCapacity))
    }
    
    func toNumber(position: Int) -> Double? {
        var isNumber: Int32 = 0
        let n = lua_tonumberx(L, Int32(position), &isNumber)
        if isNumber == 0 { return nil }
        return n
    }
    
}


func testLua() {
    let funcs: [String:Lua.Function] = [
        "foo": { L in
            println("woot!")
            L.pushNumber(12)
            return 1
        }
    ]
    
    let L = Lua()
    
    L.newTable(otherCapacity: funcs.count)
    
    for (name, fn) in funcs {
        L.pushFunction(fn)
        L.setField(name, table: -2)
    }
    
    L.setGlobal("haha")
    
    L.loadString("return haha.foo()")
    L.call(arguments: 0, returnValues: 1)
    println(L.toNumber(-1))
}
