import Foundation

public class Nil: Value, Equatable {
    
    public func push(vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
    public func kind() -> Kind { return .Nil }
    
    public class func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .Nil { return "nil" }
        return nil
    }
    
}

public func ==(lhs: Nil, rhs: Nil) -> Bool {
    return true
}
