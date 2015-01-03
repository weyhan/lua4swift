import Foundation

extension Bool: Value {
    
    internal init(_ vm: VirtualMachine) {
        self = lua_toboolean(vm.vm, -1) == 1 ? true : false
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushboolean(vm.vm, self ? 1 : 0)
    }
    
}
