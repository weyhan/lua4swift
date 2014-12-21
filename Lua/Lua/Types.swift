import Foundation

public typealias Function = () -> [Value]
public typealias UserdataPointer = UnsafeMutablePointer<Void>

public typealias TypeChecker = (() -> String, (VirtualMachine, Int) -> Bool)

public protocol Value {
    func pushValue(L: VirtualMachine)
    class func fromLua(L: VirtualMachine, at position: Int) -> Self?
    class func typeName() -> String
    class func kind() -> Kind
    class func isValid(L: VirtualMachine, at position: Int) -> Bool
    class func arg() -> TypeChecker
}

public protocol Library: Value {
    class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> [Value])]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> VirtualMachine -> [Value])]
    class func metaMethods() -> [MetaMethod<Self>]
}

public enum MetaMethod<T> {
    case GC(T -> VirtualMachine -> Void)
    case EQ(T -> T -> Bool)
}
