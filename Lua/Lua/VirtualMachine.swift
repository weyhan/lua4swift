import Foundation
import Cocoa

public let RegistryIndex = Int(SDegutisLuaRegistryIndex)

// basics
public class VirtualMachine {
    
    let luaState = luaL_newstate()
    
    var storedSwiftValues = [UserdataPointer : Any]()
    
    public init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(luaState) }
    }
    
    // execute
    
    public func loadString(str: String) -> String? {
        if luaL_loadstring(luaState, (str as NSString).UTF8String) == LUA_OK { return nil }
        return printError(String(fromLua: self, at: -1)!)
    }
    
    func printError(err: String) -> String {
        println("error: \(err)")
        return err
    }
    
    public func doString(str: String) -> String? {
        if let err = loadString(str) { return err }
        return call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    public func call(arguments: Int = 0, returnValues: Int = 0) -> String? {
        if lua_pcallk(luaState, Int32(arguments), Int32(returnValues), 0, 0, nil) == LUA_OK { return nil }
        return printError(String(fromLua: self, at: -1)!)
    }
    
    // set
    
    public func setGlobal(name: String) { lua_setglobal(luaState, (name as NSString).UTF8String) }
    public func setField(name: String, table: Int) { lua_setfield(luaState, Int32(table), (name as NSString).UTF8String) }
    public func setTable(tablePosition: Int) { lua_settable(luaState, Int32(tablePosition)) }
    public func setMetatable(position: Int) { lua_setmetatable(luaState, Int32(position)) }
    public func setMetatable(metatableName: String) { luaL_setmetatable(luaState, (metatableName as NSString).UTF8String) }
    
    
    // push
    
    public func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(luaState, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    public func pushNil()             { lua_pushnil(luaState) }
    public func pushBool(value: Bool) { lua_pushboolean(luaState, value ? 1 : 0) }
    public func pushDouble(n: Double) { lua_pushnumber(luaState, n) }
    public func pushInteger(n: Int64) { lua_pushinteger(luaState, n) }
    public func pushString(s: String) { lua_pushstring(luaState, (s as NSString).UTF8String) }
    
    public func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in
            switch fn() {
            case .Nothing:
                return 0
            case let .Value(value):
                value.pushValue(self)
                return 1
            case let .Values(values):
                for value in values {
                    value.pushValue(self)
                }
                return Int32(values.count)
            case let .Error(error):
                println("pushing error: \(error)")
                error.pushValue(self)
                lua_error(self.luaState)
                return 0 // uhh, we don't actually get here
            }
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(luaState, fp, Int32(upvalues))
    }
    
    func argError(expectedType: String, argPosition: Int) {
        luaL_argerror(luaState, Int32(argPosition), ("\(expectedType) expected, got <TODO>" as NSString).UTF8String)
    }
    
    public func pushMethod(name: String, _ types: [TypeChecker], _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction {
            for (i, (nameFn, testFn)) in enumerate(types) {
                if !testFn(self, i+1) {
                    self.argError(nameFn(), argPosition: i+1)
                }
            }
            
            return fn()
        }
        setTable(tablePosition - 2)
    }
    
    public func pushFromStack(position: Int) {
        lua_pushvalue(luaState, Int32(position))
    }
    
    public func pushField(name: String, fromTable: Int) {
        lua_getfield(luaState, Int32(fromTable), (name as NSString).UTF8String)
    }
    
    public func pop(n: Int) {
        lua_settop(luaState, -Int32(n)-1)
    }
    
    // custom types
    
    func getUserdataPointer(position: Int) -> UserdataPointer? {
        if kind(position) != .Userdata { return nil }
        return lua_touserdata(luaState, Int32(position))
    }
    
    func pushUserdataBox<T: CustomType>(ud: UserdataBox<T>) -> UserdataPointer {
        let ptr = lua_newuserdata(luaState, 1)
        setMetatable(T.metatableName())
        storedSwiftValues[ptr] = ud
        return ptr
    }
    
    func getUserdata<T: CustomType>(position: Int) -> UserdataBox<T>? {
        if let ptr = getUserdataPointer(position) {
            return storedSwiftValues[ptr]! as? UserdataBox<T>
        }
        return nil
    }
    
    public func pushCustomType<T: CustomType>(t: T.Type) {
        pushTable()
        
        // registry[metatableName] = lib
        pushFromStack(-1)
        setField(T.metatableName(), table: RegistryIndex)
        
        // setmetatable(lib, lib)
        pushFromStack(-1)
        setMetatable(-2)
        
        // lib.__index == lib
        pushFromStack(-1)
        setField("__index", table: -2)
        
        for (name, var kinds, fn) in t.instanceMethods() {
            kinds.insert(UserdataBox<T>.arg(), atIndex: 0)
            let f: Function = {
                let o: UserdataBox<T> = self.getUserdata(1)!
                return fn(o.object)(self)
            }
            pushMethod(name, kinds, f)
        }
        
        for (name, kinds, fn) in t.classMethods() {
            pushMethod(name, kinds, { fn(self) })
        }
        
        for metaMethod in T.metaMethods() {
            switch metaMethod {
            case let .GC(fn):
                pushMethod("__gc", [UserdataBox<T>.arg()]) {
                    let o: UserdataBox<T> = self.getUserdata(1)!
                    fn(o.object)(self)
                    self.storedSwiftValues[self.getUserdataPointer(1)!] = nil
                    return .Values([])
                }
            case let .EQ(fn):
                pushMethod("__eq", [UserdataBox<T>.arg(), UserdataBox<T>.arg()]) {
                    let a: UserdataBox<T> = self.getUserdata(1)!
                    let b: UserdataBox<T> = self.getUserdata(2)!
                    return .Values([fn(a.object)(b.object)])
                }
            }
        }
    }
    
    // ref
    
    public func ref(position: Int) -> Int { return Int(luaL_ref(luaState, Int32(position))) }
    public func unref(table: Int, _ position: Int) { luaL_unref(luaState, Int32(table), Int32(position)) }
    
    // uhh, misc?
    
    public func isTruthy(position: Int) -> Bool {
        return lua_toboolean(luaState, Int32(position)) != 0
    }
    
    public func absolutePosition(position: Int) -> Int { return Int(lua_absindex(luaState, Int32(position))) }
    
    // raw
    
    public func rawGet(#tablePosition: Int, index: Int) { lua_rawgeti(luaState, Int32(tablePosition), lua_Integer(index)) }
    
}
