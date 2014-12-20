import Foundation

import Cocoa

protocol LuaMetatableOwner: LuaType {
    class var metatableName: String { get }
}

enum LuaMetaMethod<T> {
    case GC((T) -> Void)
    case EQ((T, T) -> Bool)
}

protocol LuaType {}
extension String: LuaType {}
extension Int64: LuaType {}
extension Double: LuaType {}
extension Bool: LuaType {}
extension Lua.FunctionWrapper: LuaType {}
extension Lua.TableWrapper: LuaType {}
extension Lua.UserdataWrapper: LuaType {}
class LuaNilType: LuaType {}
let LuaNil = LuaNilType()

// basics
class Lua {
    
    let L = luaL_newstate()
    
    struct FunctionWrapper { let fn: Function }
    struct TableWrapper { let t: Table }
    struct UserdataWrapper { let ud: Userdata }
    
    typealias Function = () -> [LuaType]
    typealias Table = [(LuaType, LuaType)]
    
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
    
    func getValue(position: Int) -> LuaType? {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return LuaNil
        case LUA_TBOOLEAN: return getBool(position)!
        case LUA_TNUMBER: return getDouble(position)!
        case LUA_TSTRING: return getString(position)!
        case LUA_TTABLE: return Lua.TableWrapper(t: getTable(position)!)
        case LUA_TUSERDATA: return getUserdata(position)!
        case LUA_TLIGHTUSERDATA: return getUserdata(position)!
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
    
    func getTable(position: Int) -> Table? {
        if lua_type(L, Int32(position)) != LUA_TTABLE { return nil }
        var t = Table()
        lua_pushnil(L);
        while lua_next(L, Int32(position)) != 0 {
            t.append((getValue(-2)!, getValue(-1)!))
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
    
    func push(value: LuaType) {
        switch value {
        case let x as Int64: pushInteger(x)
        case let x as Double: pushDouble(x)
        case let x as Bool: pushBool(x)
        case let x as Lua.FunctionWrapper: pushFunction(x.fn)
        case let x as String: pushString(x)
        case let x as Lua.TableWrapper: pushTable(x.t)
        case let x as Lua.UserdataWrapper: pushUserdata(x.ud)
        case is LuaNilType: pushNil()
        default: break
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
    func pushNil()             { lua_pushnil(L) }
    func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    func pushDouble(n: Double) { lua_pushnumber(L, n) }
    func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in
            let results = fn()
            for result in results { self.push(result) }
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
    
    func pushMetaUserdata<T: LuaMetatableOwner>(swiftObject: T) {
        pushUserdata(swiftObject)
        pushField(T.metatableName, fromTable: Lua.RegistryIndex)
        setMetatable(-2)
    }
    
    func pushMetatable<T: LuaMetatableOwner>(metamethods: LuaMetaMethod<T>...) {
        luaL_newmetatable(L, (T.metatableName as NSString).UTF8String)
        for metaMethod in metamethods {
            switch metaMethod {
            case let .GC(fn):
                pushMethod("__gc", [.Userdata(T.metatableName), .Nil]) {
                    fn(self.getUserdata(1)!)
                    self.userdatas[self.getUserdata(1)!] = nil
                    return []
                }
            case let .EQ(fn):
                pushMethod("__gc", [.Userdata(T.metatableName), .Userdata(T.metatableName), .Nil]) {
                    let result = fn(self.getUserdata(1)!, self.getUserdata(2)!)
                    return [result]
                }
            }
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

}