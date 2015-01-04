import Foundation

extension String: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushstring(vm.vm, (self as NSString).UTF8String)
    }
    
    public func kind() -> Kind { return .String }
    
}
