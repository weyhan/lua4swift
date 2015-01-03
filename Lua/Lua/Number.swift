import Foundation

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
