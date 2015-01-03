import Foundation

extension String: Value {
    
    internal init(_ vm: VirtualMachine) {
        var len: UInt = 0
        let str = lua_tolstring(vm.vm, -1, &len)
        let data = NSData(bytes: str, length: Int(len))
        self = NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushstring(vm.vm, (self as NSString).UTF8String)
    }
    
}
