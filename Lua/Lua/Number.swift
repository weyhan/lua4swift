import Foundation

extension Double: Value {
    
    internal init(_ vm: VirtualMachine) {
        self = lua_tonumberx(vm.vm, -1, nil)
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, self)
    }
    
}

extension Int64: Value {
    
    internal init(_ vm: VirtualMachine) {
        self = lua_tointegerx(vm.vm, -1, nil)
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, self)
    }
    
}
