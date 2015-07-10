import Foundation

public enum FunctionResults {
    case Values([Value])
    case Error(String)
}

public class Function: StoredValue {
    
    public func call(args: [Value]) -> FunctionResults {
        let debugTable = vm.globals["debug"] as! Table
        let messageHandler = debugTable["traceback"]
        
        let originalStackTop = vm.stackSize()
        
        messageHandler.push(vm)
        push(vm)
        for arg in args {
            arg.push(vm)
        }
        
        let result = lua_pcallk(vm.vm, Int32(args.count), LUA_MULTRET, Int32(originalStackTop + 1), 0, nil)
        vm.remove(originalStackTop + 1)
        
        if result == LUA_OK {
            var values = [Value]()
            let numReturnValues = vm.stackSize() - originalStackTop
            
            for _ in 0..<numReturnValues {
                let v = vm.popValue(originalStackTop+1)!
                values.append(v)
            }
            
            return .Values(values)
        }
        else {
            let err = vm.popError()
            return .Error(err)
        }
    }
    
    override public func kind() -> Kind { return .Function }
    
    override public class func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .Function { return "function" }
        return nil
    }
    
}

public typealias TypeChecker = (VirtualMachine, Value) -> String?

public enum SwiftReturnValue {
    case Value(Lua.Value?)
    case Values([Lua.Value])
    case Nothing // convenience for Values([])
    case Error(String)
}

public typealias SwiftFunction = Arguments -> SwiftReturnValue

public class Arguments {
    
    internal var values = [Value]()
    
    public var string: String { return values.removeAtIndex(0) as! String }
    public var number: Number { return values.removeAtIndex(0) as! Number }
    public var boolean: Bool { return values.removeAtIndex(0) as! Bool }
    public var function: Function { return values.removeAtIndex(0) as! Function }
    public var table: Table { return values.removeAtIndex(0) as! Table }
    public var userdata: Userdata { return values.removeAtIndex(0) as! Userdata }
    public var lightUserdata: LightUserdata { return values.removeAtIndex(0) as! LightUserdata }
    public var thread: Thread { return values.removeAtIndex(0) as! Thread }
    
    public var integer: Int64 { return (values.removeAtIndex(0) as! Number).toInteger() }
    public var double: Double { return (values.removeAtIndex(0) as! Number).toDouble() }
    
    public func customType<T: CustomTypeInstance>() -> T { return (values.removeAtIndex(0) as! Userdata).toCustomType() }
    
}
