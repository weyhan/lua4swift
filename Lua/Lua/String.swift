import Foundation

public class ByteString: Value {
    
    public let value: String
    
    public init(_ s: String) {
        value = s
    }
    
    internal init(_ vm: VirtualMachine) {
        var len: UInt = 0
        let str = lua_tolstring(vm.vm, -1, &len)
        let data = NSData(bytes: str, length: Int(len))
        self.value = NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushstring(vm.vm, (value as NSString).UTF8String)
    }
    
}
