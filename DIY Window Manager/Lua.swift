import Foundation

prefix operator % { }
prefix func % (x: Int64) -> Lua.Value { return .Integer(x) }
prefix func % (x: String) -> Lua.Value { return .String(x) }
prefix func % (x: Bool) -> Lua.Value { return .Bool(x) }
prefix func % (x: Lua.Function) -> Lua.Value { return .Function(x) }
prefix func % (x: Lua.Table) -> Lua.Value { return .Table(x) }

class Lua {
    
    let L = luaL_newstate()
    
    typealias Function = (Lua) -> Int
    typealias Table = [(Value, Value)]
    
    enum Value: NilLiteralConvertible {
        case String(Swift.String)
        case Integer(Swift.Int64)
        case Double(Swift.Double)
        case Bool(Swift.Bool)
        case Function(Lua.Function)
        case Table(Lua.Table)
        case Nil
        
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
    
    // helpers
    
    private func get<T>(position: Int, _ type: Int32, _ checkType: Bool, _ f: () -> T) -> T? {
        if lua_type(L, Int32(position)) != type {
            if checkType { luaL_checktype(L, Int32(position), type) }
            return nil
        }
        return f()
    }
    
    func get(position: Int) -> Value? {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL:
            return Value.Nil
        case LUA_TBOOLEAN:
            return .Bool(toBool(position))
        case LUA_TNUMBER:
            return .Double(toNumber(position)!)
        case LUA_TSTRING:
            return .String(toString(position)!)
        case LUA_TTABLE:
            return .Table(toTable(position)!)
//        case LUA_TUSERDATA:
//            break
//        case LUA_TLIGHTUSERDATA:
//            break
        default:
            return nil
        }
    }
    
    // get
    
    func toNumber(position: Int, useArgError: Bool = false) -> Double? {
        return get(position, LUA_TNUMBER, useArgError) {
            return lua_tonumberx(self.L, Int32(position), nil)
        }
    }
    
    func toString(position: Int, useArgError: Bool = false) -> String? {
        return get(position, LUA_TSTRING, true) {
            var len: UInt = 0
            let str = lua_tolstring(self.L, Int32(position), &len)
            return NSString(CString: str, encoding: NSUTF8StringEncoding)!
        }
    }
    
    func toBool(position: Int) -> Bool {
        return lua_toboolean(L, Int32(position)) != 0
    }
    
    func toTable(position: Int) -> Table? {
        if lua_type(L, Int32(position)) != LUA_TTABLE { return nil }
        var t = Table()
        lua_pushnil(L);
        while lua_next(L, Int32(position)) != 0 {
            let pair = (get(-2)!, get(-1)!)
            t.append(pair)
            pop(1)
        }
        return t
    }
    
    // check
    
    func check(position: Int, type: Int32) {
        
    }
    
    // pop
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    // push
    
    func push(value: Value) {
        switch value {
        case let .Integer(x):
            pushInteger(x)
        case let .Double(x):
            pushNumber(x)
        case let .Bool(x):
            pushBool(x)
        case let .Function(x):
            pushFunction(x)
        case let .String(x):
            pushString(x)
        case let .Table(x):
            pushTable(x)
        case .Nil:
            pushNil()
        }
    }
    
    func pushNil() {
        lua_pushnil(L)
    }
    
    func pushBool(value: Bool) {
        lua_pushboolean(L, value ? 1 : 0)
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
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in Int32(fn(self)) }
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
            let key = L.toString(1, useArgError: true)
            let mods = L.toTable(2)
            luaL_checktype(L.L, 3, LUA_TFUNCTION)
            
            
            
            return 0
            }),
        (%"foo", %17)
    ]
    
    L.push(hotkeyLib)
    L.setGlobal("Hotkey")
    
//    L.doString("Hotkey.new('s', ['cmd', 'shift'], function() end)")
    
    L.doString("return print")
    
    
//    L.doString("return Hotkey.foo")
//    L.call(arguments: 1, returnValues: 0)
    
//    println(L.toNumber(-2))
//    println(L.toString(-1))
}
