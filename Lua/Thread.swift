import Foundation

public class Thread: StoredValue {
    
    override public func kind() -> Kind { return .Thread }
    
    override public class func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .Thread { return "thread" }
        return nil
    }
    
}
