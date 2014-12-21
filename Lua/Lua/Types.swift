import Foundation

public typealias Function = () -> [Value]
public typealias UserdataPointer = UnsafeMutablePointer<Void>

public typealias TypeChecker = (() -> String, (VM, Int) -> Bool)

public protocol Value {
    func pushValue(L: VM)
    class func fromLua(L: VM, at position: Int) -> Self?
    class func typeName() -> String
    class func kind() -> Kind
    class func isValid(L: VM, at position: Int) -> Bool
    class func arg() -> TypeChecker
}

protocol Library: Value {
    class func classMethods() -> [(String, [TypeChecker], VM -> [Value])]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> VM -> [Value])]
    class func metaMethods() -> [MetaMethod<Self>]
}

public enum MetaMethod<T> {
    case GC(T -> VM -> Void)
    case EQ(T -> T -> Bool)
}
