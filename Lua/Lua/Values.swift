//import Foundation
//
//extension String: Value {
//    public func push(vm: VirtualMachine) { vm.pushString(self) }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        if vm.kind(position) != .String { return nil }
//        var len: UInt = 0
//        let str = lua_tolstring(vm.vm, Int32(position), &len)
//        let data = NSData(bytes: str, length: Int(len))
//        self = NSString(data: data, encoding: NSUTF8StringEncoding)!
//    }
//    public static func typeName() -> String { return "string" }
//    public static func arg() -> TypeChecker { return (String.typeName(), String.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .String
//    }
//}
//
//extension Int64: Value {
//    public func push(vm: VirtualMachine) { vm.pushInteger(self) }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        if vm.kind(position) != .Number { return nil }
//        self = lua_tointegerx(vm.vm, Int32(position), nil)
//    }
//    public static func typeName() -> String { return "integer" }
//    public static func arg() -> TypeChecker { return (Int64.typeName(), Int64.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Number
//    }
//}
//
//extension Double: Value {
//    public func push(vm: VirtualMachine) { vm.pushDouble(self) }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        if vm.kind(position) != .Number { return nil }
//        self = lua_tonumberx(vm.vm, Int32(position), nil)
//    }
//    public static func typeName() -> String { return "double" }
//    public static func arg() -> TypeChecker { return (Double.typeName(), Double.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Number
//    }
//}
//
//extension Bool: Value {
//    public func push(vm: VirtualMachine) { vm.pushBool(self) }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        if vm.kind(position) != .Bool { return nil }
//        self = lua_toboolean(vm.vm, Int32(position)) != 0
//    }
//    public static func typeName() -> String { return "boolean" }
//    public static func arg() -> TypeChecker { return (Bool.typeName(), Bool.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Bool
//    }
//}
//
//// meant for putting functions into Lua only; can't take them out
//public struct FunctionBox: Value {
//    private let _fn: Function?
//    public var fn: Function { return _fn! }
//    public init(_ fn: Function) { _fn = fn }
//    
//    public func push(vm: VirtualMachine) {
//        if let fn = _fn { vm.pushFunction(fn) }
//    }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        // can't ever convert functions to a usable object
//    }
//    public static func typeName() -> String { return "function" }
//    public static func arg() -> TypeChecker { return (FunctionBox.typeName(), FunctionBox.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Function
//    }
//}
//
//public final class NilType: Value {
//    public func push(vm: VirtualMachine) { vm.pushNil() }
//    public init() {}
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        if vm.kind(position) != .Nil { return nil }
//    }
//    public class func typeName() -> String { return "nil" }
//    public class func arg() -> TypeChecker { return (NilType.typeName(), NilType.isValid) }
//    public class func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Nil
//    }
//}
//
//public let Nil = NilType()
//
//extension NSPoint: Value {
//    public func push(vm: VirtualMachine) {
//        KeyedTable<String,Double>(["x":Double(self.x), "y":Double(self.y)]).push(vm)
//    }
//    public init?(fromLua vm: VirtualMachine, at position: Int) {
//        let table = KeyedTable<String, Double>(fromLua: vm, at: position)
//        if table == nil { return nil }
//        let x = table!["x"] ?? 0
//        let y = table!["y"] ?? 0
//        self = NSPoint(x: x, y: y)
//    }
//    public static func typeName() -> String { return "point" }
//    public static func arg() -> TypeChecker { return (NSPoint.typeName(), NSPoint.isValid) }
//    public static func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        if vm.kind(position) != .Table { return false }
//        let dict = KeyedTable<String,Double>(fromLua: vm, at: position)
//        if dict == nil { return false }
//        return dict!["x"] != nil && dict!["y"] != nil
//    }
//}
