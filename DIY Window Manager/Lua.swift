import Foundation

class Lua {
    
    let L = luaL_newstate()
    
    enum Type {
        case Number(Double)
        case Fn(Function)
    }
    
    typealias Function = (Lua) -> Int
    typealias Definitions = [String: Type]
    
    private typealias CFunction = (COpaquePointer) -> Int32
    
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
    
    func newTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    func toNumber(position: Int) -> Double? {
        var isNumber: Int32 = 0
        let n = lua_tonumberx(L, Int32(position), &isNumber)
        if isNumber == 0 { return nil }
        return n
    }
    
    func newLib(defs: Definitions) {
        newTable(keyCapacity: defs.count)
        for (name, x) in defs {
            switch x {
            case let .Number(n):
                pushNumber(n)
                break
            case let .Fn(fn):
                pushFunction(fn)
            }
            setField(name, table: -2)
        }
    }
    
}


func testLua() {
    let hotkeyLib: Lua.Definitions = [
        "bind": .Fn({ L in
            println(L)
            println(lua_gettop(L.L))
            let n = L.toNumber(1)
            println(n)
            L.pushNumber(n! + 1)
            return 1
        }),
        "foo": .Number(17.1)
    ]
    
    let L = Lua(openLibs: true)
    
    L.newLib(hotkeyLib)
    L.setGlobal("Hotkey")
    
    L.loadString("return Hotkey.foo")
//    L.pushNumber(3)
    L.call(arguments: 0, returnValues: 1)
    
    println(L.toNumber(-1))
}
