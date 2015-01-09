import Foundation

extension Bool: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushboolean(vm.vm, self ? 1 : 0)
    }
    
    public func kind() -> Kind { return .Boolean }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .Boolean { return "boolean" }
        return nil
    }
    
}
