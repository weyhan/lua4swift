import Foundation

extension String: Value {
    public func pushValue(L: VirtualMachine) { L.pushString(self) }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        if L.kind(position) != .String { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L.vm, Int32(position), &len)
        let data = NSData(bytes: str, length: Int(len))
        self = NSString(data: data, encoding: NSUTF8StringEncoding)!
    }
    public static func typeName() -> String { return "string" }
    public static func arg() -> TypeChecker { return (String.typeName(), String.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .String
    }
}

extension Int64: Value {
    public func pushValue(L: VirtualMachine) { L.pushInteger(self) }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        if L.kind(position) != .Number { return nil }
        self = lua_tointegerx(L.vm, Int32(position), nil)
    }
    public static func typeName() -> String { return "integer" }
    public static func arg() -> TypeChecker { return (Int64.typeName(), Int64.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Number
    }
}

extension Double: Value {
    public func pushValue(L: VirtualMachine) { L.pushDouble(self) }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        if L.kind(position) != .Number { return nil }
        self = lua_tonumberx(L.vm, Int32(position), nil)
    }
    public static func typeName() -> String { return "double" }
    public static func arg() -> TypeChecker { return (Double.typeName(), Double.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Number
    }
}

extension Bool: Value {
    public func pushValue(L: VirtualMachine) { L.pushBool(self) }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        if L.kind(position) != .Bool { return nil }
        self = lua_toboolean(L.vm, Int32(position)) != 0
    }
    public static func typeName() -> String { return "boolean" }
    public static func arg() -> TypeChecker { return (Bool.typeName(), Bool.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Bool
    }
}

// meant for putting functions into Lua only; can't take them out
public struct FunctionBox: Value {
    private let _fn: Function?
    public var fn: Function { return _fn! }
    public init(_ fn: Function) { _fn = fn }
    
    public func pushValue(L: VirtualMachine) {
        if let fn = _fn { L.pushFunction(fn) }
    }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        // can't ever convert functions to a usable object
    }
    public static func typeName() -> String { return "function" }
    public static func arg() -> TypeChecker { return (FunctionBox.typeName(), FunctionBox.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Function
    }
}

public final class NilType: Value {
    public func pushValue(L: VirtualMachine) { L.pushNil() }
    public init() {}
    public init?(fromLua L: VirtualMachine, at position: Int) {
        if L.kind(position) != .Nil { return nil }
    }
    public class func typeName() -> String { return "nil" }
    public class func arg() -> TypeChecker { return (NilType.typeName(), NilType.isValid) }
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Nil
    }
}

public let Nil = NilType()

extension NSPoint: Value {
    public func pushValue(L: VirtualMachine) {
        KeyedTable<String,Double>(["x":Double(self.x), "y":Double(self.y)]).pushValue(L)
    }
    public init?(fromLua L: VirtualMachine, at position: Int) {
        let table = KeyedTable<String, Double>(fromLua: L, at: position)
        if table == nil { return nil }
        let x = table!["x"] ?? 0
        let y = table!["y"] ?? 0
        self = NSPoint(x: x, y: y)
    }
    public static func typeName() -> String { return "point" }
    public static func arg() -> TypeChecker { return (NSPoint.typeName(), NSPoint.isValid) }
    public static func isValid(L: VirtualMachine, at position: Int) -> Bool {
        if L.kind(position) != .Table { return false }
        let dict = KeyedTable<String,Double>(fromLua: L, at: position)
        if dict == nil { return false }
        return dict!["x"] != nil && dict!["y"] != nil
    }
}
