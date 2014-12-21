import Foundation

extension String: Value {
    func pushValue(L: VM) { L.pushString(self) }
    static func fromLua(L: VM, at position: Int) -> String? {
        if L.kind(position) != .String { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L.L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)
    }
    static func typeName() -> String { return "<String>" }
    static func kind() -> Kind { return .String }
    static func arg() -> TypeChecker { return (String.typeName, String.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

extension Int64: Value {
    func pushValue(L: VM) { L.pushInteger(self) }
    static func fromLua(L: VM, at position: Int) -> Int64? {
        if L.kind(position) != .Integer { return nil }
        return lua_tointegerx(L.L, Int32(position), nil)
    }
    static func typeName() -> String { return "<Integer>" }
    static func kind() -> Kind { return .Integer }
    static func arg() -> TypeChecker { return (Int64.typeName, Int64.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

extension Double: Value {
    func pushValue(L: VM) { L.pushDouble(self) }
    static func fromLua(L: VM, at position: Int) -> Double? {
        if L.kind(position) != .Double { return nil }
        return lua_tonumberx(L.L, Int32(position), nil)
    }
    static func typeName() -> String { return "<Double>" }
    static func kind() -> Kind { return .Double }
    static func arg() -> TypeChecker { return (Double.typeName, Double.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

extension Bool: Value {
    func pushValue(L: VM) { L.pushBool(self) }
    static func fromLua(L: VM, at position: Int) -> Bool? {
        if L.kind(position) != .Bool { return nil }
        return lua_toboolean(L.L, Int32(position)) != 0
    }
    static func typeName() -> String { return "<Boolean>" }
    static func kind() -> Kind { return .Bool }
    static func arg() -> TypeChecker { return (Bool.typeName, Bool.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

extension VM.FunctionBox: Value {
    func pushValue(L: VM) { L.pushFunction(self.fn) }
    static func fromLua(L: VM, at position: Int) -> VM.FunctionBox? {
        // can't ever convert functions to a usable object
        return nil
    }
    static func typeName() -> String { return "<Function>" }
    static func kind() -> Kind { return .Function }
    static func arg() -> TypeChecker { return (VM.FunctionBox.typeName, VM.FunctionBox.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

public final class NilType: Value {
    func pushValue(L: VM) { L.pushNil() }
    class func fromLua(L: VM, at position: Int) -> NilType? {
        if L.kind(position) != .Nil { return nil }
        return Nil
    }
    class func typeName() -> String { return "<nil>" }
    class func kind() -> Kind { return .Nil }
    class func arg() -> TypeChecker { return (NilType.typeName, NilType.isValid) }
    class func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind()
    }
}

extension NSPoint: Value {
    func pushValue(L: VM) {
        KeyedTable<String,Double>(["x":Double(self.x), "y":Double(self.y)]).pushValue(L)
    }
    static func fromLua(L: VM, at position: Int) -> NSPoint? {
        let table = KeyedTable<String, Double>.fromLua(L, at: position)
        if table == nil { return nil }
        let x = table!["x"] ?? 0
        let y = table!["y"] ?? 0
        return NSPoint(x: x, y: y)
    }
    static func typeName() -> String { return "<Point>" }
    static func kind() -> Kind { return .Table }
    static func arg() -> TypeChecker { return (NSPoint.typeName, NSPoint.isValid) }
    static func isValid(L: VM, at position: Int) -> Bool {
        if L.kind(position) != kind() { return false }
        let dict = KeyedTable<String,Double>.fromLua(L, at: position)
        if dict == nil { return false }
        return dict!["x"] != nil && dict!["y"] != nil
    }
}
