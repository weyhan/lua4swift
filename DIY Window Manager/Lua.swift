import Foundation

class Lua {
    
    let L = luaL_newstate()
    
    typealias Function = (Lua) -> Int
    
    enum Value {
        case String(Swift.String)
        case Integer(Swift.Int64)
        case Double(Swift.Double)
        case Function(Lua.Function)
        case Table([(Value, Value)])
        
        init(_ n: Swift.Int64) { self = .Integer(n) }
        init(_ n: Swift.String) { self = .String(n) }
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
    
    func toString(position: Int) -> String? {
        if lua_isstring(L, Int32(position)) == 0 { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)
    }
    
    func push(value: Value) {
        switch value {
        case let .Integer(n):
            pushInteger(n)
        case let .Double(n):
            pushNumber(n)
        case let .Function(fn):
            pushFunction(fn)
        case let .String(s):
            pushString(s)
        case let .Table(t):
            pushTable(t)
        }
    }
    
    func pushTable(pairs: [(Value, Value)]) {
        newTable(keyCapacity: pairs.count)
        let i = lua_absindex(L, -1) // overkill? dunno.
        for (k, v) in pairs {
            push(k)
            push(v)
            lua_settable(L, i)
        }
    }
    
}


func testLua() {
    let L = Lua(openLibs: true)
    
    let t = [
        (Lua.Value("bind"), Lua.Value({ L in
            L.pushNumber(L.toNumber(1)! + 1)
            L.pushString("bla")
            return 2
        })),
        (Lua.Value("t"), .Table([
            (Lua.Value("bar"), Lua.Value(27))
            ])),
        (Lua.Value("foo"), Lua.Value(17))
    ]
    
    L.pushTable(t)
    
    L.setGlobal("Hotkey")
    
    L.doString("return Hotkey.bind")
    L.doString("return Hotkey.t.bar")
    L.call(arguments: 1, returnValues: 2)
    
    println(L.toNumber(-2))
    println(L.toString(-1))
}
