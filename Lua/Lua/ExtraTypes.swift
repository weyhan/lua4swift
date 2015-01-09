import Foundation

extension NSPoint: Value {
    
    public func push(vm: VirtualMachine) {
        let t = vm.createTable()
        t["x"] = Double(self.x)
        t["y"] = Double(self.y)
        t.push(vm)
    }
    
    public func kind() -> Kind { return .Table }
    
    public static func arg(vm: VirtualMachine, value: Value) -> String? {
        if let result = Table.arg(vm, value: value) { return result }
        let t = value as Table
        if !(t["x"] is Number) || !(t["y"] is Number) { return "point" }
        return nil
    }
    
}

extension Table {
    
    public func toPoint() -> NSPoint? {
        let x = self["x"] as? Number
        let y = self["y"] as? Number
        if x == nil || y == nil { return nil }
        return NSPoint(x: x!.toDouble(), y: y!.toDouble())
    }
    
}
