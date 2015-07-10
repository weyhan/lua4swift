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
    
    internal func luaType() -> Int32 {
        switch self {
        case String: return LUA_TSTRING
        case Number: return LUA_TNUMBER
        case Boolean: return LUA_TBOOLEAN
        case Function: return LUA_TFUNCTION
        case Table: return LUA_TTABLE
        case Userdata: return LUA_TUSERDATA
        case LightUserdata: return LUA_TLIGHTUSERDATA
        case Thread: return LUA_TTHREAD
        case Nil: return LUA_TNIL
        case None: return LUA_TNONE
        }
    }
}

public class VirtualMachine {
    
    internal let vm = luaL_newstate()
    
    public var errorHandler: ErrorHandler? = { print("error: \($0)") }
    
    public init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(vm) }
    }
    
    deinit {
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
    internal func popValue(pos: Int) -> Value? {
        moveToStackTop(pos)
        var v: Value?
        switch kind(-1) {
        case .String:
            var len: Int = 0
            let str = lua_tolstring(vm, -1, &len)
            let data = NSData(bytes: str, length: Int(len))
            v = NSString(data: data, encoding: NSUTF8StringEncoding)! as String
        case .Number:
            v = Number(self)
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
    
    public var globals: Table {
        rawGet(tablePosition: RegistryIndex, index: GlobalsTable)
        return popValue(-1) as! Table
    }
    
    public var registry: Table {
        pushFromStack(RegistryIndex)
        return popValue(-1) as! Table
    }
    
    public func createFunction(body: String) -> MaybeFunction {
        if luaL_loadstring(vm, (body as NSString).UTF8String) == LUA_OK {
            return .Value(popValue(-1) as! Function)
        }
        else {
            return .Error(popError())
        }
    }
    
    public func createTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) -> Table {
        lua_createtable(vm, Int32(sequenceCapacity), Int32(keyCapacity))
        return popValue(-1) as! Table
    }
    
    internal func popError() -> String {
        let err = popValue(-1) as! String
        if let fn = errorHandler { fn(err) }
        return err
    }
    
    public func createUserdataMaybe<T: CustomTypeInstance>(o: T?) -> Userdata? {
        if let u = o {
            return createUserdata(u)
        }
        return nil
    }
    
    public func createUserdata<T: CustomTypeInstance>(o: T) -> Userdata {
        let ptr = UnsafeMutablePointer<T>(lua_newuserdata(vm, sizeof(T))) // this both pushes ptr onto stack and returns it
        ptr.initialize(o) // creates a new legit reference to o
        
        luaL_setmetatable(vm, (T.luaTypeName() as NSString).UTF8String) // this requires ptr to be on the stack
        return popValue(-1) as! Userdata // this pops ptr off stack
    }
    
    public enum EvalResults {
        case Values([Value])
        case Error(String)
    }
    
    public func eval(str: String, args: [Value] = []) -> EvalResults {
        let fn = createFunction(str)
        switch fn {
        case let .Value(f):
            let results = f.call(args)
            switch results {
            case let .Values(vs):
                return .Values(vs)
            case let .Error(e):
                return .Error(e)
            }
        case let .Error(e):
            return .Error(e)
        }
    }
    
    public func createFunction(typeCheckers: [TypeChecker], _ fn: SwiftFunction) -> Function {
        let f: @convention(block) (COpaquePointer) -> Int32 = { [weak self] _ in
            if self == nil { return 0 }
            let vm = self!
            
            // check types
            for i in 0 ..< vm.stackSize() {
                let typeChecker = typeCheckers[i]
                vm.pushFromStack(i+1)
                if let expectedType = typeChecker(vm, vm.popValue(-1)!) {
                    vm.argError(expectedType, at: i+1)
                }
            }
            
            // build args list
            let args = Arguments()
            for _ in 0 ..< vm.stackSize() {
                let arg = vm.popValue(1)!
                args.values.append(arg)
            }
            
            // call fn
            switch fn(args) {
            case .Nothing:
                return 0
            case let .Value(value):
                if let v = value {
                    v.push(vm)
                }
                else {
                    Nil().push(vm)
                }
                return 1
            case let .Values(values):
                for value in values {
                    value.push(vm)
                }
                return Int32(values.count)
            case let .Error(error):
                print("pushing error: \(error)")
                error.push(vm)
                lua_error(vm.vm)
                return 0 // uhh, we don't actually get here
            }
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        
        typealias CFunction = @convention(c) (COpaquePointer) -> Int32
        let fp = unsafeBitCast(imp, CFunction.self)
        lua_pushcclosure(vm, fp, 0)
        return popValue(-1) as! Function
    }
    
    @noreturn
    private func argError(expectedType: String, at argPosition: Int) -> Int32 {
        luaL_typerror(vm, Int32(argPosition), (expectedType as NSString).UTF8String)
    }
    
    public func createCustomType<T: CustomTypeInstance>(setup: (CustomType<T>) -> Void) -> CustomType<T> {
        lua_createtable(vm, 0, 0)
        let lib = CustomType<T>(self)
        pop()
        
        setup(lib)
        
        registry[T.luaTypeName()] = lib
        lib.becomeMetatableFor(lib)
        lib["__index"] = lib
        lib["__name"] = T.luaTypeName()
        
        let gc = lib.gc
        lib["__gc"] = createFunction([CustomType<T>.arg]) { args in
            let ud = args.userdata
            (ud.userdataPointer() as UnsafeMutablePointer<Void>).destroy()
            let o: T = ud.toCustomType()
            gc?(o)
            return .Nothing
        }
        
        if let eq = lib.eq {
            lib["__eq"] = createFunction([CustomType<T>.arg, CustomType<T>.arg]) { args in
                let a: T = args.customType()
                let b: T = args.customType()
                return .Value(eq(a, b))
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
    
    internal func ref(position: Int) -> Int { return Int(luaL_ref(vm, Int32(position))) }
    internal func unref(table: Int, _ position: Int) { luaL_unref(vm, Int32(table), Int32(position)) }
    internal func absolutePosition(position: Int) -> Int { return Int(lua_absindex(vm, Int32(position))) }
    internal func rawGet(tablePosition tablePosition: Int, index: Int) { lua_rawgeti(vm, Int32(tablePosition), lua_Integer(index)) }
    
    internal func pushFromStack(position: Int) {
        lua_pushvalue(vm, Int32(position))
    }
    
    internal func pop(n: Int = 1) {
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
