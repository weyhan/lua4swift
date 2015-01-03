import Foundation

public class Userdata: StoredValue {
    
    // TODO
    
}

public class LightUserdata: StoredValue {}

//public protocol Value {
//    class func typeName() -> String
//    class func isValid(vm: VirtualMachine, at position: Int) -> Bool
//    class func arg() -> TypeChecker
//}




public typealias TypeChecker = Value.Type //(String, (VirtualMachine, Int) -> Bool)
public typealias UserdataPointer = UnsafeMutablePointer<Void>

public protocol CustomType {
    
    class func classMethods() -> [(String, [TypeChecker], (VirtualMachine, [Value]) -> SwiftReturnValue)]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> (VirtualMachine, [Value]) -> SwiftReturnValue)]
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<Self>)
    class func metatableName() -> String
    
}

public struct MetaMethods<T> {
    init() {}
    public var gc: ((T, VirtualMachine) -> Void)?
    public var eq: ((T, T) -> Bool)?
}

//public final class UserdataBox<T: CustomType>: Value {
//    
//    var ptr: UserdataPointer?
//    private let _object: T?
//    var object: T { return _object! }
//    
//    public init(_ object: T) {
//        self._object = object
//    }
//    
//    public init?(_ object: T?) {
//        if object == nil { return nil }
//        self._object = object
//    }
//    
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        let box: UserdataBox<T> = vm.getUserdata(position)!
//        ptr = box.ptr
//        _object = box.object
//    }
//    
//    // for the time being, you can't actually return one of these from a function if you got it as an arg :'(
//    public func push(vm: VirtualMachine) {
//        // only create it if it doesn't exist yet
//        if ptr == nil { ptr = vm.pushUserdataBox(self) }
//    }
//    
//    public class func typeName() -> String {
//        return T.metatableName()
//    }
//    
//    public class func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        if vm.kind(position) != .Userdata { return false }
//        if let _: UserdataBox<T> = vm.getUserdata(position) { return true }
//        return false
//    }
//    
//    public class func arg() -> TypeChecker {
//        return (UserdataBox.typeName(), UserdataBox.isValid)
//    }
//    
//}
