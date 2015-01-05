import Foundation

extension NSPoint: Value {
    
    public func push(vm: VirtualMachine) {
        let t = vm.createTable()
        t["x"] = Double(self.x)
        t["y"] = Double(self.y)
        t.push(vm)
    }
    
    public func kind() -> Kind { return .Table }
    
}

extension Table {
    
    public func toPoint() -> NSPoint? {
        let x = self["x"] as? Number
        let y = self["y"] as? Number
        if x == nil || y == nil { return nil }
        return NSPoint(x: x!.toDouble(), y: y!.toDouble())
    }
    
}
