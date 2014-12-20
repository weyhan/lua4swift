import Foundation

import Cocoa

protocol LuaLibrary {
    class func classMethods() -> [(String, [Lua.Kind], Lua -> [LuaValue])]
    class func instanceMethods() -> [(String, [Lua.Kind], Self -> Lua -> [LuaValue])]
    class func metaMethods() -> [LuaMetaMethod<Self>]
    class var metatableName: String { get }
}

enum LuaMetaMethod<T> {
    case GC(T -> Lua -> Void)
    case EQ(T -> T -> Bool)
}

protocol LuaValue {
    func pushValue(L: Lua)
    init?(fromLua L: Lua, at: Int)
}

extension String: LuaValue {
    func pushValue(L: Lua) { L.pushString(self) }
    init?(fromLua L: Lua, at: Int) {
        self = ""
    }
}

extension Int64: LuaValue {
    func pushValue(L: Lua) { L.pushInteger(self) }
    init?(fromLua L: Lua, at: Int) {
        self = 0
    }
}

extension Double: LuaValue {
    func pushValue(L: Lua) { L.pushDouble(self) }
    init?(fromLua L: Lua, at: Int) {
        self = 0
    }
}

extension Bool: LuaValue {
    func pushValue(L: Lua) { L.pushBool(self) }
    init?(fromLua L: Lua, at: Int) {
        self = true
    }
}

extension Lua.FunctionWrapper: LuaValue {
    func pushValue(L: Lua) { L.pushFunction(self.fn) }
    init?(fromLua L: Lua, at: Int) {
        return nil
    }
}

extension Lua.TableWrapper: LuaValue {
    func pushValue(L: Lua) { L.pushTable(self.t) }
    init?(fromLua L: Lua, at: Int) {
        return nil
    }
}

extension Lua.UserdataWrapper: LuaValue {
    func pushValue(L: Lua) { L.pushUserdata(self.ud) }
    init?(fromLua L: Lua, at: Int) {
        return nil
    }
}

final class LuaNilType: LuaValue {
    func pushValue(L: Lua) { L.pushNil() }
    init(){}
    init?(fromLua L: Lua, at: Int) {
        return nil
    }
}

let LuaNil = LuaNilType()

// basics
class Lua {
    
    let L = luaL_newstate()
    
    struct FunctionWrapper { let fn: Function }
    struct TableWrapper { let t: Table }
    struct UserdataWrapper { let ud: Userdata }
    
    typealias Function = () -> [LuaValue]
    typealias Table = [(LuaValue, LuaValue)]
    
    class UserdataLibrary: LuaValue {
        init(){}
        func pushValue(L: Lua) {
            L.pushUserdata(self)
        }
        required init?(fromLua L: Lua, at: Int) {
        }
    }
    
    typealias Userdata = UnsafeMutablePointer<Void>
    var userdatas = [Userdata : Any]()
    
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
    
}

// get
extension Lua {
    
    func kind(position: Int) -> Kind {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return .Nil
        case LUA_TBOOLEAN: return .Bool
        case LUA_TNUMBER: return lua_isinteger(L, Int32(position)) == 0 ? .Double : .Integer
        case LUA_TSTRING: return .String
        case LUA_TTABLE: return .Table
        case LUA_TUSERDATA, LUA_TLIGHTUSERDATA: return .Userdata(nil)
        default: return .None
        }
    }
    
    func get(position: Int) -> LuaValue? {
        switch kind(position) {
        case .Nil: return LuaNil
        case .Bool: return getBool(position)!
        case .Integer: return getInteger(position)!
        case .Double: return getDouble(position)!
        case .String: return getString(position)!
        case .Table: return Lua.TableWrapper(t: getTable(position)!)
        case .Userdata(nil): return getUserdata(position)!
        default: return nil
        }
    }
    
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
    
    func getInteger(position: Int) -> Int64? {
        if lua_type(L, Int32(position)) != LUA_TNUMBER { return nil }
        return lua_tointegerx(L, Int32(position), nil)
    }
    
    func getTable(position: Int) -> Table? {
        if lua_type(L, Int32(position)) != LUA_TTABLE { return nil }
        var t = Table()
        lua_pushnil(L);
        while lua_next(L, Int32(position)) != 0 {
            t.append((get(-2)!, get(-1)!))
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
    
    func getTruthy(position: Int) -> Bool {
        return lua_toboolean(L, Int32(position)) != 0
    }
    
}

// push
extension Lua {
    
    func pushTable(table: Table) {
        pushTable(keyCapacity: table.count)
        let i = Int(lua_absindex(L, -1)) // overkill? dunno.
        for (key, value) in table {
            key.pushValue(self)
            value.pushValue(self)
            setTable(i)
        }
    }
    
    func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    func pushNil()             { lua_pushnil(L) }
    func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    func pushDouble(n: Double) { lua_pushnumber(L, n) }
    func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in
            let results = fn()
            for result in results { result.pushValue(self) }
            return Int32(results.count)
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
    func pushMethod(name: String, _ types: [Kind], _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction {
            for (i, t) in enumerate(types) {
                switch t {
                case let .Userdata(u) where u != nil:
                    luaL_checkudata(self.L, Int32(i+1), u!)
                default:
                    luaL_checktype(self.L, Int32(i+1), t.toLuaType())
                }
            }
            
            return fn()
        }
        setTable(tablePosition - 2)
    }
    
    func pushInstanceMethod<T: LuaLibrary>(name: String, var _ types: [Kind], _ fn: T -> Lua -> [LuaValue], tablePosition: Int = -1) {
        types.insert(.Userdata(T.metatableName), atIndex: 0)
        let f: Function = {
            let o: T = self.getUserdata(1)!
            return fn(o)(self)
        }
        pushMethod(name, types, f, tablePosition: tablePosition)
    }
    
    func pushClassMethod(name: String, var _ types: [Kind], _ fn: Lua -> [LuaValue], tablePosition: Int = -1) {
        pushMethod(name, types, { fn(self) }, tablePosition: tablePosition)
    }
    
    func pushFromStack(position: Int) {
        lua_pushvalue(L, Int32(position))
    }
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    func pushField(name: String, fromTable: Int) {
        lua_getfield(L, Int32(fromTable), (name as NSString).UTF8String)
    }
    
    func pushUserdata<T>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(L, UInt(sizeof(T))))
        userdata.memory = swiftObject
        userdatas[userdata] = swiftObject
    }
    
    func pushMetaUserdata<T: LuaLibrary>(swiftObject: T) {
        pushUserdata(swiftObject)
        pushField(T.metatableName, fromTable: Lua.RegistryIndex)
        setMetatable(-2)
    }
    
    func pushMetaMethod<T: LuaLibrary>(metaMethod: LuaMetaMethod<T>) {
        switch metaMethod {
        case let .GC(fn):
            pushMethod("__gc", [.Userdata(T.metatableName), .None]) {
                fn(self.getUserdata(1)!)(self)
                self.userdatas[self.getUserdata(1)!] = nil
                return []
            }
        case let .EQ(fn):
            pushMethod("__eq", [.Userdata(T.metatableName), .Userdata(T.metatableName), .None]) {
                let result = fn(self.getUserdata(1)!)(self.getUserdata(2)!)
                return [result]
            }
        }
    }
    
    func pushLibrary<T: LuaLibrary>(t: T.Type) {
        pushTable()
        
        // Registry.T = lib
        pushFromStack(-1)
        setField(T.metatableName, table: Lua.RegistryIndex)
        
        // setmetatable(lib, lib)
        pushFromStack(-1)
        setMetatable(-2)
        
        // lib.__index == lib
        pushFromStack(-1)
        setField("__index", table: -2)
        
        for mm in t.metaMethods() {
            pushMetaMethod(mm)
        }
        
        for (name, kinds, fn) in t.classMethods() {
            pushClassMethod(name, kinds, fn)
        }
        
        for (name, kinds, fn) in t.instanceMethods() {
            pushInstanceMethod(name, kinds, fn)
        }
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
        case Nil
        case String
        case Double
        case Integer
        case Bool
        case Function
        case Table
        case Userdata(Swift.String?)
        case None
        
        func toLuaType() -> Int32 {
            switch self {
            case String: return LUA_TSTRING
            case Double: return LUA_TNUMBER
            case Integer: return LUA_TNUMBER
            case Bool: return LUA_TBOOLEAN
            case Function: return LUA_TFUNCTION
            case Table: return LUA_TTABLE
            case Nil: return LUA_TNIL
            case let Userdata(type): return LUA_TUSERDATA
            default: return LUA_TNONE
            }
        }
    }
    
}
