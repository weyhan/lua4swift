import Foundation

// basics
class Lua {
    
    let L = luaL_newstate()
    
    typealias Function = (Lua) -> Int
    typealias Table = [(Value, Value)]
    
    typealias Userdata = UnsafeMutablePointer<Void>
    var userdatas = [Userdata : Any]()
    
    enum Value: NilLiteralConvertible {
        case String(Swift.String)
        case Integer(Swift.Int64)
        case Double(Swift.Double)
        case Bool(Swift.Bool)
        case Function(Lua.Function)
        case Table(Lua.Table)
        case Userdata(Lua.Userdata)
        case Nil
        
        init(nilLiteral: ()) { self = Nil }
    }
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
}

// execute
extension Lua {
    
    func loadString(str: String) { luaL_loadstring(L, (str as NSString).UTF8String) }
    
    func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
}

// set
extension Lua {
    
    func setGlobal(name: String) { lua_setglobal(L, (name as NSString).UTF8String) }
    func setField(name: String, table: Int) { lua_setfield(L, Int32(table), (name as NSString).UTF8String) }
    func setTable(tablePosition: Int) { lua_settable(L, Int32(tablePosition)) }
    func setMetatable(position: Int) { lua_setmetatable(L, Int32(position)) }
    
    func setMetatable(metatableName: String, position: Int = -1) {
        lua_getfield(L, Int32(Lua.RegistryIndex), (metatableName as NSString).UTF8String)
        setMetatable(position - 1)
    }
    
}

// internal helpers
extension Lua {
    
    func get(position: Int) -> Value? {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return Value.Nil
        case LUA_TBOOLEAN: return .Bool(getBool(position)!)
        case LUA_TNUMBER: return .Double(getDouble(position)!)
        case LUA_TSTRING: return .String(getString(position)!)
        case LUA_TTABLE: return .Table(getTable(position)!)
        case LUA_TUSERDATA: return .Userdata(getUserdata(position)!)
        case LUA_TLIGHTUSERDATA: return .Userdata(getUserdata(position)!)
        default: return nil
        }
    }
    
}

// get
extension Lua {
    
    func getString(position: Int) -> String? {
        if lua_type(L, Int32(position)) != LUA_TSTRING { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)
    }
    
    func getBool(position: Int) -> Bool? {
        if lua_type(L, Int32(position)) != LUA_TBOOLEAN { return nil }
        return lua_toboolean(L, Int32(position)) != 0
    }
    
    func getDouble(position: Int) -> Double? {
        if lua_type(L, Int32(position)) != LUA_TNUMBER { return nil }
        return lua_tonumberx(L, Int32(position), nil)
    }
    
    func getTable(position: Int) -> Table? {
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
    
    func getUserdata(position: Int) -> Userdata? {
        if lua_type(L, Int32(position)) != LUA_TUSERDATA { return nil }
        return Userdata(lua_touserdata(L, Int32(position)))
    }
    
    func getUserdata<T>(position: Int) -> T? {
        if let ud = getUserdata(position) { return UnsafeMutablePointer<T>(ud).memory }
        return nil
    }
    
    func getUserdata<T>(position: Int, metatableName: String) -> T? {
        if luaL_testudata(L, Int32(position), (metatableName as NSString).UTF8String) == nil { return nil }
        return getUserdata(position)
    }
    
    func getTruthy(position: Int) -> Bool {
        return lua_toboolean(L, Int32(position)) != 0
    }
    
}

// push
extension Lua {
    
    func push(value: Value) {
        switch value {
        case let .Integer(x): pushInteger(x)
        case let .Double(x): pushDouble(x)
        case let .Bool(x): pushBool(x)
        case let .Function(x): pushFunction(x)
        case let .String(x): pushString(x)
        case let .Table(x): pushTable(x)
        case let .Userdata(x): pushUserdata(x)
        case .Nil: pushNil()
        }
    }
    
    func pushTable(table: Table) {
        pushTable(keyCapacity: table.count)
        let i = Int(lua_absindex(L, -1)) // overkill? dunno.
        for (key, value) in table {
            push(key)
            push(value)
            setTable(i)
        }
    }
    
    func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) { lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity)) }
    func pushMetatable(s: String) -> Bool { return luaL_newmetatable(L, (s as NSString).UTF8String) != 0 }
    func pushNil()             { lua_pushnil(L) }
    func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    func pushDouble(n: Double) { lua_pushnumber(L, n) }
    func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    func pushMetatable(s: String, _ setup: () -> Void) {
        pushMetatable(s)
        setup()
        setMetatable(-2)
    }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in Int32(fn(self)) }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
    func pushMethod(name: String, _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction(fn)
        setTable(tablePosition - 2)
    }
    
    func pushFromStack(position: Int) {
        lua_pushvalue(L, Int32(position))
    }
    
    func pushOntoTable(key: Value, _ value: Value, table: Int = -1) {
        push(key)
        push(value)
        setTable(table-2)
    }
    
    func pushMethod(key: Value, _ value: Function, table: Int = -1) {
        push(key)
        pushFunction(value)
        setTable(table-2)
    }
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    func pushUserdata<T>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(L, UInt(sizeof(T))))
        userdata.memory = swiftObject
        userdatas[userdata] = swiftObject
    }
    
}

protocol LuaMetatableOwner {
    class var metatableName: String { get }
}

// meta methods
extension Lua {
    
    func pushMetaMethodGC<T: LuaMetatableOwner>(t: T.Type, _ fn: (Lua, T) -> Void, tablePosition: Int = -1) {
        pushString("__gc")
        pushFunction { L in
            L.checkArgs(.Userdata(T.metatableName), .None)
            fn(L, L.getUserdata(1)!)
            L.userdatas[L.getUserdata(1)!] = nil
            return 0
        }
        setTable(tablePosition - 2)
    }
    
}

// ref
extension Lua {
    
    class var RegistryIndex: Int { return Int(SDegutisLuaRegistryIndex) } // ugh swift
    
    func ref(position: Int) -> Int { return Int(luaL_ref(L, Int32(position))) }
    func unref(table: Int, _ position: Int) { luaL_unref(L, Int32(table), Int32(position)) }
    
}

// uhh, misc?
extension Lua {
    
    func absolutePosition(position: Int) -> Int { return Int(lua_absindex(L, Int32(position))) }
    
}

// raw
extension Lua {
    
    func rawGet(#tablePosition: Int, index: Int) {
        lua_rawgeti(L, Int32(tablePosition), lua_Integer(index))
    }
    
}

// type checking
extension Lua {
    
    enum Kind {
        case String
        case Number
        case Bool
        case Function
        case Table
        case Nil
        case None
        case Userdata(Swift.String?)
        
        func toLuaType() -> Int32 {
            switch self {
            case String: return LUA_TSTRING
            case Number: return LUA_TNUMBER
            case Bool: return LUA_TBOOLEAN
            case Function: return LUA_TFUNCTION
            case Table: return LUA_TTABLE
            case Nil: return LUA_TNIL
            case let Userdata(type): return LUA_TUSERDATA
            default: return LUA_TNONE
            }
        }
    }
    
    func checkArgs(types: Kind...) {
        for (i, t) in enumerate(types) {
            switch t {
            case let .Userdata(ud) where ud != nil:
                luaL_checkudata(L, Int32(i+1), ud!)
            default:
                luaL_checktype(L, Int32(i+1), t.toLuaType())
            }
        }
    }
    
}
