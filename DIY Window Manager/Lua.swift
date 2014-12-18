import Foundation

prefix operator % { }
prefix func % (x: Int64) -> Lua.Value { return .Integer(x) }
prefix func % (x: String) -> Lua.Value { return .String(x) }
prefix func % (x: Bool) -> Lua.Value { return .Bool(x) }
prefix func % (x: Lua.Function) -> Lua.Value { return .Function(x) }
prefix func % (x: Lua.Table) -> Lua.Value { return .Table(x) }

class Lua {
    
    private struct KeepAliveCollection {
        
        var bag = Array<LuaUserdata>()
        
        mutating func add(o: LuaUserdata) {
            bag.append(o)
        }
        
        mutating func remove(o: LuaUserdata) {
            for (i, x) in enumerate(bag) {
                if o == x {
                    bag.removeAtIndex(i)
                    return
                }
            }
        }
        
    }
    
    let L = luaL_newstate()
    private var userdatas = KeepAliveCollection()
    
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
    
    enum Kind {
        case String
        case Number
        case Bool
        case Function
        case Table
        case Nil
        case None
        
        func toLuaType() -> Int32 {
            switch self {
            case String: return LUA_TSTRING
            case Number: return LUA_TNUMBER
            case Bool: return LUA_TBOOLEAN
            case Function: return LUA_TFUNCTION
            case Table: return LUA_TTABLE
            case Nil: return LUA_TNIL
            default: return LUA_TNONE
            }
        }
    }
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
    // eval
    
    func loadString(str: String) { luaL_loadstring(L, (str as NSString).UTF8String) }
    
    func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
    // set
    
    func setGlobal(name: String) { lua_setglobal(L, (name as NSString).UTF8String) }
    func setField(name: String, table: Int) { lua_setfield(L, Int32(table), (name as NSString).UTF8String) }
    func setTable(tablePosition: Int) { lua_settable(L, Int32(tablePosition)) }
    
    // helpers
    
    func get(position: Int) -> Value? {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return Value.Nil
        case LUA_TBOOLEAN: return .Bool(getBool(position))
        case LUA_TNUMBER: return .Double(getNumber(position))
        case LUA_TSTRING: return .String(getString(position))
        case LUA_TTABLE: return .Table(getTable(position))
//        case LUA_TUSERDATA:
//            break
//        case LUA_TLIGHTUSERDATA:
//            break
        default: return nil
        }
    }
    
    // get
    
    func getString(position: Int) -> String {
        var len: UInt = 0
        let str = lua_tolstring(L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)!
    }
    
    func getBool(position: Int) -> Bool { return lua_toboolean(L, Int32(position)) != 0 }
    func getNumber(position: Int) -> Double { return lua_tonumberx(L, Int32(position), nil) }
    
    func getTable(position: Int) -> Table {
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
    
    func checkArgs(types: Kind...) {
        for (i, t) in enumerate(types) {
            luaL_checktype(L, Int32(i+1), t.toLuaType())
        }
    }
    
    // pop
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    // push
    
    func push(value: Value) {
        switch value {
        case let .Integer(x): pushInteger(x)
        case let .Double(x): pushNumber(x)
        case let .Bool(x): pushBool(x)
        case let .Function(x): pushFunction(x)
        case let .String(x): pushString(x)
        case let .Table(x): pushTable(x)
        case .Nil: pushNil()
        }
    }
    
    // currently unused; is needed? maybe could be split up
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
    func pushNil()             { lua_pushnil(L) }
    func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    func pushNumber(n: Double) { lua_pushnumber(L, n) }
    func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in Int32(fn(self)) }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
    func pushFromStack(position: Int) {
        lua_pushvalue(L, Int32(position))
    }
    
    // ref
    
    class var RegistryIndex: Int { return Int(SDegutisLuaRegistryIndex) } // ugh swift
    
    func ref(position: Int) -> Int { return Int(luaL_ref(L, Int32(position))) }
    func unref(table: Int, _ position: Int) { luaL_unref(L, Int32(table), Int32(position)) }
    
    // uhh, convenience?
    
    // totally questionable function; avoid using in case it needs to just be deleted for being useless
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
    
    // raw get
    
    func rawGet(#tablePosition: Int, index: Int) {
        lua_rawgeti(L, Int32(tablePosition), lua_Integer(index))
    }
    
    // userdata
    
    func toUserdata<T>(position: Int) -> T {
        return UnsafeMutablePointer<T>(lua_touserdata(L, Int32(position))).memory
    }
    
    func pushUserdata<T: LuaUserdata>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(L, UInt(sizeof(T))))
        userdata.memory = swiftObject
        userdatas.add(swiftObject)
        
//        if luaL_newmetatable(L, (T.userdataName() as NSString).UTF8String) != 0 {
//            pushMethod(%"__gc") { L in
//                let a: T = L.toUserdata(1)
//                self.userdatas.remove(a)
//                a.gc()
//                return 0
//            }
//        }
    }
    
    func absolutePosition(position: Int) -> Int { return Int(lua_absindex(L, Int32(position))) }
    
    func pushOntoTable(position: Int, _ contents: Table) {
        let tableIndex = absolutePosition(position)
        for (key, value) in contents {
            push(key)
            push(value)
            setTable(tableIndex)
        }
    }
    
    func pushLibrary(lib: Library) {
        // push lib table
        pushTable()
        
        // add metatable, add meta methods to lib table
        luaL_newmetatable(L, (lib.metaTableName as NSString).UTF8String)
        pushOntoTable(-1, lib.metaMethods)
        lua_setmetatable(L, -2)
        
        // add instance methods to lib table
        pushOntoTable(-1, lib.instanceMethods)
        
        // add class methods to lib table
        pushOntoTable(-1, lib.instanceMethods)
        
        // set lib table as its own __index key
        pushFromStack(-1)
        setField("__index", table: -2)
    }
    
    struct Library {
        var metaTableName: String
        var instanceMethods: Table
        var classMethods: Table
        var metaMethods: Table // omit __gc
    }
    
}

protocol LuaUserdata {
    var id: Int { get set }
}

func ==(a: LuaUserdata, b: LuaUserdata) -> Bool { return a.id == b.id }


class LuaHotkey: LuaUserdata {
    var id: Int = 0
    let fn: Int = 0
    init(fn: Int) { self.fn = fn }
    
    func call(L: Lua) {
        L.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
        L.call(arguments: 1, returnValues: 0)
    }
}


func testLua() {
    let L = Lua(openLibs: true)
    
    let hotkeyLib = Lua.Library(
        metaTableName: "Hotkey",
        instanceMethods: [(%"foo", %17)],
        classMethods: [(%"new", %{ L in
            L.checkArgs(.String, .Table, .Function, .None)
            let key = L.getString(1)
            let mods = L.getTable(2)
            L.pushFromStack(3)
            let i = L.ref(Lua.RegistryIndex)
            L.pushUserdata(LuaHotkey(fn: i))
            return 1
            })],
        metaMethods: [(%"__eq", %{ L in
            let a: LuaHotkey = L.toUserdata(1)
            let b: LuaHotkey = L.toUserdata(2)
            L.pushBool(a == b)
            return 1
            }),
            (%"__gc", %{ L in
                let a: LuaHotkey = L.toUserdata(1)
                L.unref(Lua.RegistryIndex, a.fn)
                return 0
                })])
    
    L.pushLibrary(hotkeyLib)
    L.setGlobal("Hotkey")
    
//    L.doString("Hotkey.new('s', {'cmd', 'shift'}, function() end)")
}
