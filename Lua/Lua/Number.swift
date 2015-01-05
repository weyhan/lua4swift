import Foundation

public class Number: StoredValue {
    
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
    
}

extension Double: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
}

extension Int64: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
}

extension Int: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, Int64(self))
    }
    
    public func kind() -> Kind { return .Number }
    
}
