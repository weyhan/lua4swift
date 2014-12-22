import Foundation

public enum ReturnValue {
    case Value(Lua.Value)
    case Values([Lua.Value])
    case Nothing // convenience for Values([])
    case Error(String)
}

public typealias Function = () -> ReturnValue
public typealias TypeChecker = (() -> String, (VirtualMachine, Int) -> Bool)
public typealias UserdataPointer = UnsafeMutablePointer<Void>

public protocol Value {
    func pushValue(L: VirtualMachine)
    class func fromLua(L: VirtualMachine, at position: Int) -> Self?
    class func typeName() -> String
    class func isValid(L: VirtualMachine, at position: Int) -> Bool
    class func arg() -> TypeChecker
}

public protocol UserType: Value {
    class func classMethods() -> [(String, [TypeChecker], VirtualMachine -> ReturnValue)]
    class func instanceMethods() -> [(String, [TypeChecker], Self -> VirtualMachine -> ReturnValue)]
    class func metaMethods() -> [MetaMethod<Self>]
}

public enum MetaMethod<T> {
    case GC(T -> VirtualMachine -> Void)
    case EQ(T -> T -> Bool)
}
