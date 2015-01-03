import Foundation

public protocol Value {
    func push(vm: VirtualMachine)
}

public class StoredValue: Value {
    
    private let refPosition: Int
    internal weak var vm: VirtualMachine?
    
    internal init(_ vm: VirtualMachine) {
        self.vm = vm
        vm.pushFromStack(-1)
        refPosition = vm.ref(RegistryIndex)
    }
    
    deinit {
        vm?.unref(RegistryIndex, refPosition)
    }
    
    public func push(vm: VirtualMachine) {
        vm.rawGet(tablePosition: RegistryIndex, index: refPosition)
    }
    
}

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
