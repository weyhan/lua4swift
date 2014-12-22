import Foundation

public protocol UserType {
    class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> ReturnValue)]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> VirtualMachine -> ReturnValue)]
    class func metaMethods() -> [MetaMethod<Self>]
    class func typeName() -> String
}

public enum MetaMethod<T> {
    case GC(T -> VirtualMachine -> Void)
    case EQ(T -> T -> Bool)
}

public final class Userdata<T: UserType>: Value {
    
    let object: T
    
    public init(_ object: T) {
        self.object = object
    }
    
    public func pushValue(L: VirtualMachine) {
        L.pushUserdata(self)
    }
    
    public required init?(fromLua L: VirtualMachine, at position: Int) {
        let ud: Userdata<T> = L.getUserdata(position)!
        object = ud.object
    }
    
    public class func typeName() -> String {
        return T.typeName()
    }
    
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return false
    }
    
    public class func arg() -> TypeChecker {
        return (Userdata.typeName, Userdata.isValid)
    }
    
    public class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> ReturnValue)] {
        return T.classMethods()
    }
    
    public class func instanceMethods() -> [(String, [TypeChecker], T -> VirtualMachine -> ReturnValue)] {
        return T.instanceMethods()
    }
    
    public class func metaMethods() -> [MetaMethod<T>] {
        return T.metaMethods()
    }
    
}
