import Foundation

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
