import Foundation

public class Nil: Value, Equatable {
    
    public func push(vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
    public func kind() -> Kind { return .Nil }
    
}

public func ==(lhs: Nil, rhs: Nil) -> Bool {
    return true
}
