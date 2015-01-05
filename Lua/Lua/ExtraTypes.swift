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
        let x = self["x"]
        let y = self["y"]
        if x.kind() != .Number || y.kind() != .Number { return nil }
        return NSPoint(x: Double(x)!, y: Double(y)!)
    }
    
}