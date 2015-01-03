import Foundation
import Cocoa

private let RegistryIndex = Int(SDegutisLuaRegistryIndex)
private let GlobalsTable = Int(LUA_RIDX_GLOBALS)

public typealias ErrorHandler = (String) -> Void

public protocol Value {
    func push(vm: VirtualMachine)
}

private enum Kind {
    case None
    case Nil
    case Bool
    case Number
    case String
    case Function
    case Table
    case Userdata
    case LightUserdata
    case Thread
}

public class StoredValue: Value {
    
    private let refPosition: Int
    private let vm: VirtualMachine
    
    private init(_ vm: VirtualMachine) {
        self.vm = vm
        refPosition = vm.ref(RegistryIndex)
    }
    
    deinit {
        vm.unref(RegistryIndex, refPosition)
    }
    
    public func push(vm: VirtualMachine) {
        vm.rawGet(tablePosition: RegistryIndex, index: refPosition)
    }
    
}

public class FreeNumber: Value {
    
    public let value: Double
    
    public init(_ n: Double) {
        value = n
    }
    
    private init(_ vm: VirtualMachine) {
        value = lua_tonumberx(vm.vm, -1, nil)
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, value)
    }
    
}

public class FreeString: Value {
    
    public let value: String
    
    public init(_ s: String) {
        value = s
    }
    
    private init(_ vm: VirtualMachine) {
        var len: UInt = 0
        let str = lua_tolstring(vm.vm, -1, &len)
        let data = NSData(bytes: str, length: Int(len))
        self.value = NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushstring(vm.vm, (value as NSString).UTF8String)
    }
    
}

public enum FunctionResults {
    case Values([Value])
    case Error(String)
}

public class StoredFunction: StoredValue {
    
    public func call(args: [Value]) -> [Value] {
        let size = vm.stackSize()
        
        push(vm)
        for arg in args {
            arg.push(vm)
        }
        
        return []
    }
    
}

public class FreeBoolean: Value {
    
    public let value: Bool
    
    public init(_ b: Bool) {
        value = b
    }
    
    private init(_ vm: VirtualMachine) {
        value = lua_toboolean(vm.vm, -1) == 1 ? true : false
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushboolean(vm.vm, value ? 1 : 0)
    }
    
}

public class StoredUserdata: StoredValue {
}

public class StoredLightUserdata: StoredValue {
}

public class StoredTable: StoredValue {
    
    public func get(key: Value) -> Value {
        push(vm)
        
        key.push(vm)
        lua_gettable(vm.vm, -2)
        let v = vm.value(-1)
        
        vm.pop()
        return v!
    }
    
    public func set(#key: Value, value: Value) {
        push(vm)
        
        key.push(vm)
        value.push(vm)
        lua_settable(vm.vm, -3)
        
        vm.pop()
    }
    
}

public class StoredThread: StoredValue {
}

public class Nil: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
}

public enum MaybeFunction {
    case Value(StoredFunction)
    case Error(String)
}

// basics
public class VirtualMachine {
    
    let vm = luaL_newstate()
//    var storedSwiftValues = [UserdataPointer : Any]()
    
    public var errorHandler: ErrorHandler? = { println("error: \($0)") }
    
    public init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(vm) }
    }
    
    deinit {
        println("lua dead")
        lua_close(vm)
    }
    
    private func kind(position: Int) -> Kind {
        switch lua_type(vm, Int32(position)) {
        case LUA_TNIL: return .Nil
        case LUA_TBOOLEAN: return .Bool
        case LUA_TNUMBER: return .Number
        case LUA_TSTRING: return .String
        case LUA_TFUNCTION: return .Function
        case LUA_TTABLE: return .Table
        case LUA_TUSERDATA: return .Userdata
        case LUA_TLIGHTUSERDATA: return .LightUserdata
        case LUA_TTHREAD: return .Thread
        default: return .None
        }
    }
    
    public func globalTable() -> StoredTable {
        rawGet(tablePosition: RegistryIndex, index: GlobalsTable)
        return value(-1) as StoredTable
    }
    
    public func value(pos: Int) -> Value? {
        moveToStackTop(pos)
        var v: Value?
        switch kind(pos) {
        case .String: v = FreeString(self)
        case .Number: v = FreeNumber(self)
        case .Bool: v = FreeBoolean(self)
        case .Function: v = StoredFunction(self)
        case .Table: v = StoredTable(self)
        case .Userdata: v = StoredUserdata(self)
        case .LightUserdata: v = StoredLightUserdata(self)
        case .Thread: v = StoredThread(self)
        case .Nil: v = Nil()
        case .None: break
        }
        pop()
        return v
    }
    
    public func createFunction(body: String) -> MaybeFunction {
        if luaL_loadstring(vm, (body as NSString).UTF8String) == LUA_OK {
            return .Value(StoredFunction(self))
        }
        else {
            return .Error(popError())
        }
    }
    
    func popError() -> String {
        let err = FreeString(self).value
        if let fn = errorHandler { fn(err) }
        return err
    }
    
//    public func doString(str: String) -> String? {
//        if let err = loadString(str) { return err }
//        return call(arguments: 0, returnValues: Int(LUA_MULTRET))
//    }
//    
//    public func call(arguments: Int = 0, returnValues: Int = 0) -> String? {
//        var messageHandler = -1 // top of stack
//        messageHandler -= arguments // before all arguments
//        messageHandler -= 1 // before function
//        
//        pushGlobal("debug")
//        pushField("traceback")
//        remove(-2) // pop debug
//        insert(messageHandler) // push before fn
//        
//        var err: String?
//        
//        if lua_pcallk(vm, Int32(arguments), Int32(returnValues), Int32(messageHandler), 0, nil) != LUA_OK {
//            err = popError()
//        }
//        
//        pop(1) // message handler
//        
//        return err
//    }
//    
//    // set
//    
//    public func setGlobal(name: String) { lua_setglobal(vm, (name as NSString).UTF8String) }
//    public func setField(name: String, table: Int) { lua_setfield(vm, Int32(table), (name as NSString).UTF8String) }
//    public func setTable(tablePosition: Int) { lua_settable(vm, Int32(tablePosition)) }
//    public func setMetatable(position: Int) { lua_setmetatable(vm, Int32(position)) }
//    public func setMetatable(metatableName: String) { luaL_setmetatable(vm, (metatableName as NSString).UTF8String) }
//    
//    
//    // push
//    
//    public func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
//        lua_createtable(vm, Int32(sequenceCapacity), Int32(keyCapacity))
//    }
//    
//    public func pushNil()             { lua_pushnil(vm) }
//    public func pushBool(value: Bool) { lua_pushboolean(vm, value ? 1 : 0) }
//    public func pushDouble(n: Double) { lua_pushnumber(vm, n) }
//    public func pushInteger(n: Int64) { lua_pushinteger(vm, n) }
//    public func pushString(s: String) { lua_pushstring(vm, (s as NSString).UTF8String) }
//    
//    public func pushFunction(fn: Function, upvalues: Int = 0) {
//        let f: @objc_block (COpaquePointer) -> Int32 = { [weak self] _ in
//            if self == nil { return 0 }
//            
//            switch fn() {
//            case .Nothing:
//                return 0
//            case let .Value(value):
//                if let v = value {
//                    v.push(self!)
//                }
//                else {
//                    self!.pushNil()
//                }
//                return 1
//            case let .Values(values):
//                for value in values {
//                    value.push(self!)
//                }
//                return Int32(values.count)
//            case let .Error(error):
//                println("pushing error: \(error)")
////                error.push(self!) // TODO: uncomment
//                lua_error(self!.vm)
//                return 0 // uhh, we don't actually get here
//            }
//        }
//        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
//        let imp = imp_implementationWithBlock(block)
//        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
//        lua_pushcclosure(vm, fp, Int32(upvalues))
//    }
//    
//    func argError(expectedType: String, argPosition: Int) -> ReturnValue {
//        luaL_typeerror(vm, Int32(argPosition), (expectedType as NSString).UTF8String)
//        return .Nothing
//        // TODO: return .Error instead
//    }
//    
//    public func pushMethod(name: String, _ types: [TypeChecker], _ fn: Function, tablePosition: Int = -1) {
//        pushString(name)
//        pushFunction { [weak self] in
//            if self == nil { return .Nothing }
//            for (i, (nameFn, testFn)) in enumerate(types) {
//                if !testFn(self!, i+1) {
//                    return self!.argError(nameFn, argPosition: i+1)
//                }
//            }
//            
//            return fn()
//        }
//        setTable(tablePosition - 2)
//    }
    
//    public func pushGlobal(name: String) {
//        lua_getglobal(vm, (name as NSString).UTF8String)
//    }
//    
//    public func pushField(name: String, fromTable: Int = -1) {
//        lua_getfield(vm, Int32(fromTable), (name as NSString).UTF8String)
//    }
    
//    public func insert(position: Int) {
//        rotate(position, n: 1)
//    }
//    
//    // custom types
//    
////    func getUserdataPointer(position: Int) -> UserdataPointer? {
////        if kind(position) != .Userdata { return nil }
////        return lua_touserdata(vm, Int32(position))
////    }
////    
////    func pushUserdataBox<T: CustomType>(ud: UserdataBox<T>) -> UserdataPointer {
////        let ptr = lua_newuserdata(vm, 1)
////        setMetatable(T.metatableName())
////        storedSwiftValues[ptr] = ud
////        return ptr
////    }
////    
////    func getUserdata<T: CustomType>(position: Int) -> UserdataBox<T>? {
////        if let ptr = getUserdataPointer(position) {
////            return storedSwiftValues[ptr]! as? UserdataBox<T>
////        }
////        return nil
////    }
////    
////    public func pushCustomType<T: CustomType>(t: T.Type) {
////        pushTable()
////        
////        // registry[metatableName] = lib
////        pushFromStack(-1)
////        setField(T.metatableName(), table: RegistryIndex)
////        
////        // setmetatable(lib, lib)
////        pushFromStack(-1)
////        setMetatable(-2)
////        
////        // lib.__index == lib
////        pushFromStack(-1)
////        setField("__index", table: -2)
////        
////        // lib.__name = the given metatable name // TODO: seems broken maybe?
////        pushString(t.metatableName())
////        setField("__name", table: -2)
////        
////        for (name, var kinds, fn) in t.instanceMethods() {
////            kinds.insert(UserdataBox<T>.arg(), atIndex: 0)
////            let f: Function = { [weak self] in
////                if self == nil { return .Nothing }
////                let o: UserdataBox<T> = self!.getUserdata(1)!
////                self!.remove(1)
////                return fn(o.object)(self!)
////            }
////            pushMethod(name, kinds, f)
////        }
////        
////        for (name, kinds, fn) in t.classMethods() {
////            pushMethod(name, kinds, { [weak self] in
////                if self == nil { return .Nothing }
////                return fn(self!)
////            })
////        }
////        
////        var metaMethods = MetaMethods<T>()
////        T.setMetaMethods(&metaMethods)
////        
////        let gc = metaMethods.gc
////        pushMethod("__gc", [UserdataBox<T>.arg()]) { [weak self] in
////            println("called!")
//////            if self == nil { return .Nothing }
////            let o: UserdataBox<T> = self!.getUserdata(1)!
////            gc?(o.object, self!)
////            self!.storedSwiftValues[self!.getUserdataPointer(1)!] = nil
////            return .Values([])
////        }
////        
////        if let eq = metaMethods.eq {
////            pushMethod("__eq", [UserdataBox<T>.arg(), UserdataBox<T>.arg()]) { [weak self] in
////                if self == nil { return .Nothing }
////                let a: UserdataBox<T> = self!.getUserdata(1)!
////                let b: UserdataBox<T> = self!.getUserdata(2)!
////                return .Values([eq(a.object, b.object)])
////            }
////        }
////    }
//    
//    // ref
    
    
//    public func isTruthy(position: Int) -> Bool {
//        return lua_toboolean(vm, Int32(position)) != 0
//    }
    
    private func moveToStackTop(var position: Int) {
        if position == -1 { return }
        position = absolutePosition(position)
        pushFromStack(position)
        remove(position)
    }
    
    private func ref(position: Int) -> Int { return Int(luaL_ref(vm, Int32(position))) }
    private func unref(table: Int, _ position: Int) { luaL_unref(vm, Int32(table), Int32(position)) }
    private func absolutePosition(position: Int) -> Int { return Int(lua_absindex(vm, Int32(position))) }
    private func rawGet(#tablePosition: Int, index: Int) { lua_rawgeti(vm, Int32(tablePosition), lua_Integer(index)) }
    
    private func pushFromStack(position: Int) {
        lua_pushvalue(vm, Int32(position))
    }
    
    private func pop(_ n: Int = 1) {
        lua_settop(vm, -Int32(n)-1)
    }
    
    private func rotate(position: Int, n: Int) {
        lua_rotate(vm, Int32(position), Int32(n))
    }
    
    private func remove(position: Int) {
        rotate(position, n: -1)
        pop(1)
    }
    
    private func stackSize() -> Int {
        return Int(lua_gettop(vm))
    }
    
}
