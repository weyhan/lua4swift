import Foundation

public enum FunctionResults {
    case Values([Value])
    case Error(String)
}

public class Function: StoredValue {
    
    public func call(args: [Value]) -> FunctionResults {
        let globals = vm.globalTable()
        let debugTable = globals[ByteString("debug")] as Table
        let messageHandler = debugTable[ByteString("traceback")]
        
        let originalStackTop = vm.stackSize()
        
        messageHandler.push(vm)
        let messageHandlerPosition = originalStackTop + 1
        
        push(vm)
        for arg in args {
            arg.push(vm)
        }
        
        // stack contains: [traceback, fn, *args]
        
        var err: String?
        if lua_pcallk(vm.vm, Int32(args.count), LUA_MULTRET, Int32(messageHandlerPosition), 0, nil) != LUA_OK {
            err = vm.popError()
        }
        
        vm.remove(messageHandlerPosition)
        
        // stack now contains either [] or [*results]
        
        if let error = err {
            return .Error(error)
        }
        else {
            var values = [Value]()
            
            let numReturnValues = vm.stackSize() - originalStackTop
            
            for i in 1...numReturnValues {
                let v = vm.value(originalStackTop+1)
                debugPrintln(v)
                values.append(v!)
            }
            
            return .Values(values)
        }
    }
    
}
