import Foundation

extension Bool: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushboolean(vm.vm, self ? 1 : 0)
    }
    
    public func kind() -> Kind { return .Boolean }
    
}
