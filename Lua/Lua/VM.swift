import Foundation
import Cocoa

public let RegistryIndex = Int(SDegutisLuaRegistryIndex)

// basics
public class VM {
    
    let L = luaL_newstate()
    
    var storedSwiftValues = [UserdataPointer : Any]()
    
    public init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
    // execute
    
    public func loadString(str: String) { luaL_loadstring(L, (str as NSString).UTF8String) }
    
    public func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    public func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
    // set
    
    public func setGlobal(name: String) { lua_setglobal(L, (name as NSString).UTF8String) }
    public func setField(name: String, table: Int) { lua_setfield(L, Int32(table), (name as NSString).UTF8String) }
    public func setTable(tablePosition: Int) { lua_settable(L, Int32(tablePosition)) }
    public func setMetatable(position: Int) { lua_setmetatable(L, Int32(position)) }
    
    // get
    
    public func kind(position: Int) -> Kind {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return .Nil
        case LUA_TBOOLEAN: return .Bool
        case LUA_TNUMBER: return lua_isinteger(L, Int32(position)) == 0 ? .Double : .Integer
        case LUA_TSTRING: return .String
        case LUA_TFUNCTION: return .Function
        case LUA_TTABLE: return .Table
        case LUA_TUSERDATA, LUA_TLIGHTUSERDATA: return .Userdata
        case LUA_TTHREAD: return .Thread
        default: return .None
        }
    }
    
    public func getUserdataPointer(position: Int) -> UserdataPointer? {
        if lua_type(L, Int32(position)) != LUA_TUSERDATA { return nil }
        return lua_touserdata(L, Int32(position))
    }
    
    public func getUserdata(position: Int) -> Value? {
        if lua_type(L, Int32(position)) != LUA_TUSERDATA { return nil }
        return UnsafeMutablePointer<Value>(getUserdataPointer(position)!).memory
    }
    
    public func isTruthy(position: Int) -> Bool {
        return lua_toboolean(L, Int32(position)) != 0
    }
    
    // push
    
    public func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    public func pushNil()             { lua_pushnil(L) }
    public func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    public func pushDouble(n: Double) { lua_pushnumber(L, n) }
    public func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    public func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    public func pushFunction(fn: Function, upvalues: Int = 0) {
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
    
    public func pushMethod(name: String, _ types: [TypeChecker], _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction {
            for (i, (nameFn, testFn)) in enumerate(types) {
                if !testFn(self, i+1) {
                    luaL_argerror(self.L, Int32(i+1), ("\(nameFn()) expected, got <TODO>" as NSString).UTF8String)
                }
            }
            
            return fn()
        }
        setTable(tablePosition - 2)
    }
    
    public func pushInstanceMethod<T: Library>(name: String, var _ types: [TypeChecker], _ fn: T -> VM -> [Value], tablePosition: Int = -1) {
        types.insert(T.arg(), atIndex: 0)
        let f: Function = {
            let o = T.fromLua(self, at: 1)!
            return fn(o)(self)
        }
        pushMethod(name, types, f, tablePosition: tablePosition)
    }
    
    public func pushClassMethod(name: String, var _ types: [TypeChecker], _ fn: VM -> [Value], tablePosition: Int = -1) {
        pushMethod(name, types, { fn(self) }, tablePosition: tablePosition)
    }
    
    public func pushFromStack(position: Int) {
        lua_pushvalue(L, Int32(position))
    }
    
    public func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    public func pushField(name: String, fromTable: Int) {
        lua_getfield(L, Int32(fromTable), (name as NSString).UTF8String)
    }
    
    public func pushUserdata<T>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(L, UInt(sizeof(T))))
        userdata.memory = swiftObject
        storedSwiftValues[userdata] = swiftObject
    }
    
    public func pushMetaMethod<T: Library>(metaMethod: MetaMethod<T>) {
        switch metaMethod {
        case let .GC(fn):
            pushMethod("__gc", [T.arg()]) {
                fn(T.fromLua(self, at: 1)!)(self)
                self.storedSwiftValues[self.getUserdataPointer(1)!] = nil
                return []
            }
        case let .EQ(fn):
            pushMethod("__eq", [T.arg(), T.arg()]) {
                let a = T.fromLua(self, at: 1)!
                let b = T.fromLua(self, at: 2)!
                return [fn(a)(b)]
            }
        }
    }
    
    public func pushLibrary<T: Library>(t: T.Type) {
        pushTable()
        
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
    
    // ref
    
    public func ref(position: Int) -> Int { return Int(luaL_ref(L, Int32(position))) }
    public func unref(table: Int, _ position: Int) { luaL_unref(L, Int32(table), Int32(position)) }
    
    // uhh, misc?
    
    public func absolutePosition(position: Int) -> Int { return Int(lua_absindex(L, Int32(position))) }
    
    // raw
    
    public func rawGet(#tablePosition: Int, index: Int) {
        lua_rawgeti(L, Int32(tablePosition), lua_Integer(index))
    }
    
}
