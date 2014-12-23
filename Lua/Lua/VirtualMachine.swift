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
    
    public func loadString(str: String) { luaL_loadstring(luaState, (str as NSString).UTF8String) }
    
    public func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    public func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(luaState, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
    // set
    
    public func setGlobal(name: String) { lua_setglobal(luaState, (name as NSString).UTF8String) }
    public func setField(name: String, table: Int) { lua_setfield(luaState, Int32(table), (name as NSString).UTF8String) }
    public func setTable(tablePosition: Int) { lua_settable(luaState, Int32(tablePosition)) }
    public func setMetatable(position: Int) { lua_setmetatable(luaState, Int32(position)) }
    
    // get
    
    public func getUserdataPointer(position: Int) -> UserdataPointer? {
        if lua_type(luaState, Int32(position)) != LUA_TUSERDATA { return nil }
        return lua_touserdata(luaState, Int32(position))
    }
    
    public func getUserdata<T: Value>(position: Int) -> T? {
        if lua_type(luaState, Int32(position)) != LUA_TUSERDATA { return nil }
        return UnsafeMutablePointer<T>(getUserdataPointer(position)!).memory
    }
    
    public func isTruthy(position: Int) -> Bool {
        return lua_toboolean(luaState, Int32(position)) != 0
    }
    
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
                return 0 // uhh, we don't actually return here
            }
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(luaState, fp, Int32(upvalues))
    }
    
    public func pushMethod(name: String, _ types: [TypeChecker], _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction {
            for (i, (nameFn, testFn)) in enumerate(types) {
                if !testFn(self, i+1) {
                    luaL_argerror(self.luaState, Int32(i+1), ("\(nameFn()) expected, got <TODO>" as NSString).UTF8String)
                }
            }
            
            return fn()
        }
        setTable(tablePosition - 2)
    }
    
//    public func pushInstanceMethod<T>(name: String, var _ types: [TypeChecker], _ fn: T -> VirtualMachine -> ReturnValue, tablePosition: Int = -1) {
//        types.insert(T.arg(), atIndex: 0)
//        let f: Function = {
//            let o = T(fromLua: self, at: 1)!
//            return fn(o)(self)
//        }
//        pushMethod(name, types, f, tablePosition: tablePosition)
//    }
    
    public func pushClassMethod(name: String, var _ types: [TypeChecker], _ fn: VirtualMachine -> ReturnValue, tablePosition: Int = -1) {
        pushMethod(name, types, { fn(self) }, tablePosition: tablePosition)
    }
    
    public func pushFromStack(position: Int) {
        lua_pushvalue(luaState, Int32(position))
    }
    
    public func pop(n: Int) {
        lua_settop(luaState, -Int32(n)-1)
    }
    
    public func pushField(name: String, fromTable: Int) {
        lua_getfield(luaState, Int32(fromTable), (name as NSString).UTF8String)
    }
    
    public func pushUserdata<T>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(luaState, UInt(sizeof(T))))
        userdata.initialize(swiftObject)
        storedSwiftValues[userdata] = swiftObject
    }
    
//    public func pushMetaMethod<T, U where T: Userdata<U>, U: CustomType>(metaMethod: MetaMethod<T>) {
//        switch metaMethod {
//        case let .GC(fn):
//            T.arg()
//            pushMethod("__gc", [T.arg()]) {
//                fn(T(fromLua: self, at: 1)!)(self)
//                self.storedSwiftValues[self.getUserdataPointer(1)!] = nil
//                return .Values([])
//            }
//        case let .EQ(fn):
//            pushMethod("__eq", [T.arg(), T.arg()]) {
//                let a = T(fromLua: self, at: 1)!
//                let b = T(fromLua: self, at: 2)!
//                return .Values([fn(a)(b)])
//            }
//        }
//    }
    
    public func pushCustomType() {
        pushTable()
        
        // setmetatable(lib, lib)
        pushFromStack(-1)
        setMetatable(-2)
        
        // lib.__index == lib
        pushFromStack(-1)
        setField("__index", table: -2)
        
//        for mm in T.metaMethods() {
//            U(fromLua: self, at: 1)
//            pushMetaMethod(mm)
//        }
        
//        for (name, kinds, fn) in t.classMethods() {
//            pushClassMethod(name, kinds, fn)
//        }
//        
//        for (name, kinds, fn) in t.instanceMethods() {
//            pushInstanceMethod(name, kinds, fn)
//        }
    }
    
    // ref
    
    public func ref(position: Int) -> Int { return Int(luaL_ref(luaState, Int32(position))) }
    public func unref(table: Int, _ position: Int) { luaL_unref(luaState, Int32(table), Int32(position)) }
    
    // uhh, misc?
    
    public func absolutePosition(position: Int) -> Int { return Int(lua_absindex(luaState, Int32(position))) }
    
    // raw
    
    public func rawGet(#tablePosition: Int, index: Int) {
        lua_rawgeti(luaState, Int32(tablePosition), lua_Integer(index))
    }
    
}
