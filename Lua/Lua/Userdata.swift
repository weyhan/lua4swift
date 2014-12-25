import Foundation

public protocol CustomType {
    
    class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> ReturnValue)]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> VirtualMachine -> ReturnValue)]
    class func metaMethods() -> [MetaMethod<Self>]
    class func metatableName() -> String
    
}

public enum MetaMethod<T> {
    case GC((T, VirtualMachine) -> Void)
    case EQ((T, T) -> Bool)
}

public final class UserdataBox<T: CustomType>: Value {
    
    var ptr: UserdataPointer?
    private let _object: T?
    var object: T { return _object! }
    
    public init(_ object: T) {
        self._object = object
    }
    
    public init?(_ object: T?) {
        if object == nil { return nil }
        self._object = object
    }
    
    public init?(fromLua L: VirtualMachine, at position: Int) {
        let box: UserdataBox<T> = L.getUserdata(position)!
        ptr = box.ptr
        _object = box.object
    }
    
    // for the time being, you can't actually return one of these from a function if you got it as an arg :'(
    public func pushValue(L: VirtualMachine) {
        // only create it if it doesn't exist yet
        if ptr == nil { ptr = L.pushUserdataBox(self) }
    }
    
    public class func typeName() -> String {
        return T.metatableName()
    }
    
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
        if L.kind(position) != .Userdata { return false }
        if let _: UserdataBox<T> = L.getUserdata(position) { return true }
        return false
    }
    
    public class func arg() -> TypeChecker {
        return (UserdataBox.typeName(), UserdataBox.isValid)
    }
    
}
