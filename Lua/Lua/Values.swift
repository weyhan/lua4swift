import Foundation

public class StoredValue: Value {
    
    private let refPosition: Int
    private let vm: VirtualMachine
    
    internal init(_ vm: VirtualMachine) {
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

public class Number: Value {
    
    public let value: Double
    
    public init(_ n: Double) {
        value = n
    }
    
    internal init(_ vm: VirtualMachine) {
        value = lua_tonumberx(vm.vm, -1, nil)
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, value)
    }
    
}

public class ByteString: Value {
    
    public let value: String
    
    public init(_ s: String) {
        value = s
    }
    
    internal init(_ vm: VirtualMachine) {
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

public class Boolean: Value {
    
    public let value: Bool
    
    public init(_ b: Bool) {
        value = b
    }
    
    internal init(_ vm: VirtualMachine) {
        value = lua_toboolean(vm.vm, -1) == 1 ? true : false
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushboolean(vm.vm, value ? 1 : 0)
    }
    
}

public class Userdata: StoredValue {
}

public class LightUserdata: StoredValue {}

public class Table: StoredValue {
    
    public subscript(key: Value) -> Value {
        get {
            push(vm)
            
            key.push(vm)
            lua_gettable(vm.vm, -2)
            let v = vm.value(-1)
            
            vm.pop()
            return v!
        }
        
        set {
            push(vm)
            
            key.push(vm)
            newValue.push(vm)
            lua_settable(vm.vm, -3)
            
            vm.pop()
        }
    }
    
}

public class StoredThread: StoredValue {}

public class Nil: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
}
