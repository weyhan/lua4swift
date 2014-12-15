import Foundation

class Lua {
    
    let L = luaL_newstate()
    
    typealias Function = (Lua) -> Int
    typealias Definitions = [(String, Value)]
    
    enum Value {
        case String(Swift.String)
        case Integer(Swift.Int64)
        case Double(Swift.Double)
        case Function(Lua.Function)
        
        init(_ n: Swift.Int64) { self = .Integer(n) }
        init(_ fn: Lua.Function) { self = .Function(fn) }
    }
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { L in Int32(fn(self)) }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = unsafeBitCast(imp, CFunctionPointer<(COpaquePointer) -> Int32>.self)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
    func setGlobal(name: String) {
        lua_setglobal(L, (name as NSString).UTF8String)
    }
    
    func loadString(str: String) {
        luaL_loadstring(L, (str as NSString).UTF8String)
    }
    
    func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    func pushNumber(n: Double) {
        lua_pushnumber(L, n)
    }
    
    func pushInteger(n: Int64) {
        lua_pushinteger(L, n)
    }
    
    func pushString(s: String) {
        lua_pushstring(L, (s as NSString).UTF8String)
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
    
    func push(value: Value) {
        switch value {
        case let .Integer(n):
            pushInteger(n)
            break
        case let .Double(n):
            pushNumber(n)
            break
        case let .Function(fn):
            pushFunction(fn)
        case let .String(s):
            pushString(s)
        default:
            break
        }
    }
    
    func newLib(defs: Definitions) {
        newTable(keyCapacity: defs.count)
        for (name, x) in defs {
            push(x)
            setField(name, table: -2)
        }
    }
    
}


func testLua() {
    let hotkeyLib: Lua.Definitions = [
        ("bind", Lua.Value({ L in
            L.pushNumber(L.toNumber(1)! + 1)
            return 1
        })),
        ("foo", Lua.Value(17)),
    ]
    
    let L = Lua(openLibs: true)
    
    L.newLib(hotkeyLib)
    L.setGlobal("Hotkey")
    
    L.doString("return Hotkey.bind")
    L.doString("return Hotkey.foo")
    L.call(arguments: 1, returnValues: 1)
    
    println(L.toNumber(-1))
}
