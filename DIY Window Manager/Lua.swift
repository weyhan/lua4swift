import Foundation

prefix operator % { }
prefix func % (x: Int64) -> Lua.Value { return Lua.Value(x) }
prefix func % (x: String) -> Lua.Value { return Lua.Value(x) }
prefix func % (x: Lua.Function) -> Lua.Value { return Lua.Value(x) }
prefix func % (x: Lua.Table) -> Lua.Value { return Lua.Value(x) }

class Lua {
    
    let L = luaL_newstate()
    
    typealias Function = (Lua) -> Int
    typealias Table = [(Value, Value)]
    
    enum Value: NilLiteralConvertible {
        case String(Swift.String)
        case Integer(Swift.Int64)
        case Double(Swift.Double)
        case Function(Lua.Function)
        case Table(Lua.Table)
        case Nil
        
        init(_ n: Swift.String) { self = .String(n) }
        init(_ n: Swift.Int64) { self = .Integer(n) }
        init(_ n: Swift.Double) { self = .Double(n) }
        init(_ fn: Lua.Function) { self = .Function(fn) }
        init(_ fn: Lua.Table) { self = .Table(fn) }
        init(nilLiteral: ()) { self = Nil }
    }
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
    // eval
    
    func loadString(str: String) {
        luaL_loadstring(L, (str as NSString).UTF8String)
    }
    
    func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
    // set
    
    func setGlobal(name: String) {
        lua_setglobal(L, (name as NSString).UTF8String)
    }
    
    func setField(name: String, table: Int) {
        lua_setfield(L, Int32(table), (name as NSString).UTF8String)
    }
    
    // get
    
    func toNumber(position: Int) -> Double? {
        if lua_isnumber(L, Int32(position)) == 0 { return nil }
        return lua_tonumberx(L, Int32(position), nil)
    }
    
    func toString(position: Int) -> String? {
        if lua_isstring(L, Int32(position)) == 0 { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)
    }
    
    func toFunction(position: Int) {
        
    }
    
    func get(position: Int) -> Value? {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL:
            return Value.Nil
//        case LUA_TBOOLEAN:
//            break
//        case LUA_TLIGHTUSERDATA:
//            break
        case LUA_TNUMBER:
            return Value(toNumber(position)!)
        case LUA_TSTRING:
            return Value(toString(position)!)
//        case LUA_TTABLE:
//            break
//        case LUA_TFUNCTION:
//            break
//        case LUA_TUSERDATA:
//            break
//        case LUA_TTHREAD:
//            break
        default:
            return nil
        }
    }
    
    func toTable(position: Int) -> Table {
        var t = Table()
        lua_pushnil(L);
        while lua_next(L, Int32(position)) != 0 {
            let pair = (get(-2)!, get(-1)!)
            t.append(pair)
            pop(1)
        }
        return t
    }
    
    // pop
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    // push
    
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
        case .Nil:
            pushNil()
        }
    }
    
    func pushNil() {
        lua_pushnil(L)
    }
    
    func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    func pushTable(table: Table) {
        pushTable(keyCapacity: table.count)
        let i = lua_absindex(L, -1) // overkill? dunno.
        for (key, value) in table {
            push(key)
            push(value)
            lua_settable(L, i)
        }
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
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { L in Int32(fn(self)) }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = unsafeBitCast(imp, CFunctionPointer<(COpaquePointer) -> Int32>.self)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
}


func testLua() {
    let L = Lua(openLibs: true)
    
    let hotkeyLib = %[
        (%"new", %{ L in
            let key = L.toString(1)
            let mods = L.toTable(2)
            let fn = L.toFunction(3)
            
            
            
            
            return 0
            }),
        (%"foo", %17)
    ]
    
    L.push(hotkeyLib)
    L.setGlobal("Hotkey")
    
    L.doString("Hotkey.new('s', ['cmd', 'shift'], function() end)")
    
//    L.doString("return Hotkey.bind")
//    L.doString("return Hotkey.t.bar")
//    L.call(arguments: 1, returnValues: 2)
//    
//    println(L.toNumber(-2))
//    println(L.toString(-1))
}
