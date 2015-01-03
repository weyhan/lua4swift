import Foundation

public class Nil: Value {
    
    public func push(vm: VirtualMachine) {
        lua_pushnil(vm.vm)
    }
    
}
