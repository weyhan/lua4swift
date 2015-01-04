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

public typealias SwiftFunction = ([Value]) -> SwiftReturnValue
