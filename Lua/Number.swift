import Foundation

public class Number: StoredValue, CustomDebugStringConvertible {
    
    override public func kind() -> Kind { return .Number }
    
    public func toDouble() -> Double {
        push(vm)
        let v = lua_tonumberx(vm.vm, -1, nil)
        vm.pop()
        return v
    }
    
    public func toInteger() -> Int64 {
        push(vm)
        let v = lua_tointegerx(vm.vm, -1, nil)
        vm.pop()
        return v
    }
    
    public var debugDescription: String {
        push(vm)
        let isInteger = lua_isinteger(vm.vm, -1) != 0
        vm.pop()
        
        if isInteger { return toInteger().description }
        else { return toDouble().description }
    }
    
    override public class func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .Number { return "number" }
        return nil
    }
    
}

extension Double: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        value.push(vm)
        let isDouble = lua_isinteger(vm.vm, -1) != 0
        vm.pop()
        if !isDouble { return "double" }
        return nil
    }
    
}

extension Int64: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        value.push(vm)
        let isDouble = lua_isinteger(vm.vm, -1) != 0
        vm.pop()
        if !isDouble { return "integer" }
        return nil
    }
    
}

extension Int: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, Int64(self))
    }
    
    public func kind() -> Kind { return .Number }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        return Int64.arg(vm, value: value)
    }
    
}
