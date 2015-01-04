import Foundation
import Cocoa

internal let RegistryIndex = Int(SDegutisLuaRegistryIndex)
private let GlobalsTable = Int(LUA_RIDX_GLOBALS)

public enum MaybeFunction {
    case Value(Function)
    case Error(String)
}

public typealias ErrorHandler = (String) -> Void

public enum Kind {
    case String
    case Number
    case Boolean
    case Function
    case Table
    case Userdata
    case LightUserdata
    case Thread
    case Nil
    case None
}

public class VirtualMachine {
    
    internal let vm = luaL_newstate()
    internal var storedSwiftValues = [UserdataPointer : Any]()
    
    public var errorHandler: ErrorHandler? = { println("error: \($0)") }
    
    public init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(vm) }
    }
    
    deinit {
        println("lua state is dead.")
        lua_close(vm)
    }
    
    internal func kind(pos: Int) -> Kind {
        switch lua_type(vm, Int32(pos)) {
        case LUA_TSTRING: return .String
        case LUA_TNUMBER: return .Number
        case LUA_TBOOLEAN: return .Boolean
        case LUA_TFUNCTION: return .Function
        case LUA_TTABLE: return .Table
        case LUA_TUSERDATA: return .Userdata
        case LUA_TLIGHTUSERDATA: return .LightUserdata
        case LUA_TTHREAD: return .Thread
        case LUA_TNIL: return .Nil
        default: return .None
        }
    }
    
    // pops the value off the stack completely and returns it
    internal func value(pos: Int) -> Value? {
        moveToStackTop(pos)
        var v: Value?
        switch kind(-1) {
        case .String:
            var len: UInt = 0
            let str = lua_tolstring(vm, -1, &len)
            let data = NSData(bytes: str, length: Int(len))
            v = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        case .Number:
            if lua_isinteger(vm, -1) != 0 {
                v = lua_tointegerx(vm, -1, nil)
            }
            else {
                v = lua_tonumberx(vm, -1, nil)
            }
        case .Boolean:
            v = lua_toboolean(vm, -1) == 1 ? true : false
        case .Function:
            v = Function(self)
        case .Table:
            v = Table(self)
        case .Userdata:
            v = Userdata(self)
        case .LightUserdata:
            v = LightUserdata(self)
        case .Thread:
            v = Thread(self)
        case .Nil:
            v = Nil()
        default: break
        }
        pop()
        return v
    }
    
    public func globalTable() -> Table {
        rawGet(tablePosition: RegistryIndex, index: GlobalsTable)
        return value(-1) as Table
    }
    
    public func registryTable() -> Table {
        pushFromStack(RegistryIndex)
        return value(-1) as Table
    }
    
    public func createFunction(body: String) -> MaybeFunction {
        if luaL_loadstring(vm, (body as NSString).UTF8String) == LUA_OK {
            return .Value(value(-1) as Function)
        }
        else {
            return .Error(popError())
        }
    }
    
    public func createTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) -> Table {
        lua_createtable(vm, Int32(sequenceCapacity), Int32(keyCapacity))
        return value(-1) as Table
    }
    
    internal func popError() -> String {
        let err = value(-1) as String
        if let fn = errorHandler { fn(err) }
        return err
    }
    
    public func createUserdata<T: CustomType>(o: T) -> Userdata {
        // Note: we just alloc 1 byte cuz malloc prolly needs > 0 but we dun use it
        
        let ptr = lua_newuserdata(vm, 1) // this pushes ptr onto stack and returns it too
        let ud = value(-1) as Userdata // this pops ptr off stack
        setMetatable(T.metatableName())
        storedSwiftValues[ptr] = ud
        return ud
    }
    
    public func createFunction(fn: SwiftFunction, upvalues: Int = 0) -> Function {
        let f: @objc_block (COpaquePointer) -> Int32 = { [weak self] _ in
            if self == nil { return 0 }
            
            var args = [Value]()
            for _ in 0 ..< self!.stackSize() {
                args.append(self!.value(1)!)
            }
            
            switch fn(args) {
            case .Nothing:
                return 0
            case let .Value(value):
                if let v = value {
                    v.push(self!)
                }
                else {
                    Nil().push(self!)
                }
                return 1
            case let .Values(values):
                for value in values {
                    value.push(self!)
                }
                return Int32(values.count)
            case let .Error(error):
                println("pushing error: \(error)")
                error.push(self!)
                lua_error(self!.vm)
                return 0 // uhh, we don't actually get here
            }
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(vm, fp, Int32(upvalues))
        return value(-1) as Function
    }
    
    func argError(expectedType: String, argPosition: Int) -> SwiftReturnValue {
        luaL_typeerror(vm, Int32(argPosition), (expectedType as NSString).UTF8String)
        return .Nothing
        // TODO: return .Error instead
    }
    
    public func checkTypes(args: [Value], _ kinds: [Kind]) -> String? {
        for (i, kind) in enumerate(kinds) {
            let v = args[i]
            if v.kind() != kind { return "TODO" }
        }
        return nil
    }
    
    public func createCustomType<T: CustomType>(t: T.Type) -> Table {
        let lib = createTable()
        
        let registry = registryTable()
        registry[T.metatableName()] = lib
        
        setMetatable(lib, metaTable: lib)
        
        lib["__index"] = lib
        lib["__name"] = T.metatableName()  // TODO: seems broken maybe?
        
        for (name, fn) in t.instanceMethods() {
            let f = createFunction { [weak self] (var args: [Value]) in
                // TODO: type checking
                // TODO: first arg is known to be Userdata (and Library of type T)
                if self == nil { return .Nothing }
                let o: T = (args.removeAtIndex(0) as Userdata).toCustomType()!
                return fn(o)(self!, args)
            }
            
            lib[name] = f
        }
        
        for (name, fn) in t.classMethods() {
            let f = createFunction { [weak self] (var args: [Value]) in
                // TODO: type checking
                if self == nil { return .Nothing }
                return fn(self!, args)
            }
            
            lib[name] = f
        }
        
        var metaMethods = MetaMethods<T>()
        T.setMetaMethods(&metaMethods)
        
        let gc = metaMethods.gc
        
        lib["__gc"] = createFunction { [weak self] (var args: [Value]) in
            println("called!")
            // if self == nil { return .Nothing }
            
            let ud = args.removeAtIndex(0) as Userdata
            let o: T = ud.toCustomType()!
            gc?(o, self!)
            self!.storedSwiftValues[ud.toUserdataPointer()] = nil
            return .Values([])
        }
        
        if let eq = metaMethods.eq {
            lib["__eq"] = createFunction { [weak self] (var args: [Value]) in
                if self == nil { return .Nothing }
                let a: T = (args.removeAtIndex(0) as Userdata).toCustomType()!
                let b: T = (args.removeAtIndex(0) as Userdata).toCustomType()!
                return .Values([eq(a, b)])
            }
        }
        
        return lib
    }
    
    // stack
    
    internal func moveToStackTop(var position: Int) {
        if position == -1 || position == stackSize() { return }
        position = absolutePosition(position)
        pushFromStack(position)
        remove(position)
    }
    
    internal func setMetatable(thing: Value, metaTable: Value) {
        thing.push(self)
        metaTable.push(self)
        lua_setmetatable(vm, -2)
        pop() // thing
    }
    
//    internal func insert(position: Int) { rotate(position, n: 1) }
    
    internal func setMetatable(metatableName: String) { luaL_setmetatable(vm, (metatableName as NSString).UTF8String) }
    internal func ref(position: Int) -> Int { return Int(luaL_ref(vm, Int32(position))) }
    internal func unref(table: Int, _ position: Int) { luaL_unref(vm, Int32(table), Int32(position)) }
    internal func absolutePosition(position: Int) -> Int { return Int(lua_absindex(vm, Int32(position))) }
    internal func rawGet(#tablePosition: Int, index: Int) { lua_rawgeti(vm, Int32(tablePosition), lua_Integer(index)) }
    
    internal func pushFromStack(position: Int) {
        lua_pushvalue(vm, Int32(position))
    }
    
    internal func pop(_ n: Int = 1) {
        lua_settop(vm, -Int32(n)-1)
    }
    
    internal func rotate(position: Int, n: Int) {
        lua_rotate(vm, Int32(position), Int32(n))
    }
    
    internal func remove(position: Int) {
        rotate(position, n: -1)
        pop(1)
    }
    
    internal func stackSize() -> Int {
        return Int(lua_gettop(vm))
    }
    
}
