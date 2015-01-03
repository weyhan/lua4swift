import Foundation

public typealias ErrorHandler = (String) -> Void

public protocol Value {
    func push(vm: VirtualMachine)
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
