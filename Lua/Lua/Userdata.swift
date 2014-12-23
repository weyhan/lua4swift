import Foundation




//public protocol CustomType {
//    class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> ReturnValue)]
//    class func instanceMethods() -> [(String, [TypeChecker], Self -> VirtualMachine -> ReturnValue)]
//    class func metaMethods() -> [MetaMethod<Self>]
//    class func typeName() -> String
//}
//
//public enum MetaMethod<T> {
//    case GC(T -> VirtualMachine -> Void)
//    case EQ(T -> T -> Bool)
//}

//public final class Userdata<T: CustomType>: Value {
//    
//    let object: T
//    
//    public init(_ object: T) {
//        self.object = object
//    }
//    
//    public func pushValue(L: VirtualMachine) {
//        L.pushUserdata(self)
//    }
//    
//    public required init?(fromLua L: VirtualMachine, at position: Int) {
//        let ud: Userdata<T> = L.getUserdata(position)!
//        object = ud.object
//    }
//    
//    public class func typeName() -> String {
//        return T.typeName()
//    }
//    
//    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
//        return false
//    }
//    
//    public class func arg() -> TypeChecker {
//        return (Userdata.typeName, Userdata.isValid)
//    }
//    
//}
