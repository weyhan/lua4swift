import Foundation

public protocol Value {
    func push(vm: VirtualMachine)
}

public class StoredValue: Value {
    
    private let refPosition: Int
    internal let vm: VirtualMachine
    
    internal init(_ vm: VirtualMachine) {
        self.vm = vm
        refPosition = vm.ref(RegistryIndex)
    }
    
    deinit {
        vm.unref(RegistryIndex, refPosition)
    }
    
    public func push(vm: VirtualMachine) {
        vm.rawGet(tablePosition: RegistryIndex, index: refPosition)
    }
    
}



//public enum ReturnValue {
//    case Value(Lua.Value?)
//    case Values([Lua.Value])
//    case Nothing // convenience for Values([])
//    case Error(String)
//}
//
//public typealias Function = () -> ReturnValue
//public typealias TypeChecker = (String, (VirtualMachine, Int) -> Bool)
//public typealias UserdataPointer = UnsafeMutablePointer<Void>
//
//public protocol Value {
//    func push(vm: VirtualMachine)
//    init?(fromLua vm: VirtualMachine, at position: Int)
//    class func typeName() -> String
//    class func isValid(vm: VirtualMachine, at position: Int) -> Bool
//    class func arg() -> TypeChecker
//}
