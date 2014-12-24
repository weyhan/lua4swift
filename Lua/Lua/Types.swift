import Foundation

public enum ReturnValue {
    case Value(Lua.Value?)
    case Values([Lua.Value])
    case Nothing // convenience for Values([])
    case Error(String)
}

public typealias Function = () -> ReturnValue
public typealias TypeChecker = (String, (VirtualMachine, Int) -> Bool)
public typealias UserdataPointer = UnsafeMutablePointer<Void>

public protocol Value {
    func pushValue(L: VirtualMachine)
    init?(fromLua L: VirtualMachine, at position: Int)
    class func kind() -> Kind
    class func typeName() -> String
    class func isValid(L: VirtualMachine, at position: Int) -> Bool
    class func arg() -> TypeChecker
}

public typealias ErrorHandler = (String) -> Void
