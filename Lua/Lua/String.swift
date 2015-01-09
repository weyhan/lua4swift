import Foundation

extension String: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushstring(vm.vm, (self as NSString).UTF8String)
    }
    
    public func kind() -> Kind { return .String }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .String { return "string" }
        return nil
    }
    
}
