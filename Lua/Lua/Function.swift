import Foundation

public enum FunctionResults {
    case Values([Value])
    case Error(String)
}

public class Function: StoredValue {
    
    public func call(args: [Value]) -> FunctionResults {
        let globals = vm.globalTable
        let debugTable = globals["debug"] as Table
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
            
            for i in 0..<numReturnValues {
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
    
}

public enum SwiftReturnValue {
    case Value(Lua.Value?)
    case Values([Lua.Value])
    case Nothing // convenience for Values([])
    case Error(String)
}

public typealias SwiftFunction = Arguments -> SwiftReturnValue

public class Arguments {
    
    internal var args: [Value]
    internal init(args: [Value]) {
        self.args = args
    }
    
    public var string: String { return args.removeAtIndex(0) as String }
    public var number: Number { return args.removeAtIndex(0) as Number }
    public var boolean: Bool { return args.removeAtIndex(0) as Bool }
    public var function: Function { return args.removeAtIndex(0) as Function }
    public var table: Table { return args.removeAtIndex(0) as Table }
    public var userdata: Userdata { return args.removeAtIndex(0) as Userdata }
    public var lightUserdata: LightUserdata { return args.removeAtIndex(0) as LightUserdata }
    public var thread: Thread { return args.removeAtIndex(0) as Thread }
    
}
