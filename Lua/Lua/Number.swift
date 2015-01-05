import Foundation

extension Double: Value {
    
    init?(_ v: Value) {
        if v.kind() != .Number { return nil }
        if let d = v as? Double { self = d }
        else { self = Double(v as Int64) }
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushnumber(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
}

extension Int64: Value {
    
    init?(_ v: Value) {
        if v.kind() != .Number { return nil }
        if let d = v as? Int64 { self = d }
        else { self = Int64(v as Double) }
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, self)
    }
    
    public func kind() -> Kind { return .Number }
    
}

extension Int: Value {
    
    init?(_ v: Value) {
        if v.kind() != .Number { return nil }
        if let d = v as? Int64 { self = Int(d) }
        else { self = Int(v as Double) }
    }
    
    public func push(vm: VirtualMachine) {
        lua_pushinteger(vm.vm, Int64(self))
    }
    
    public func kind() -> Kind { return .Number }
    
}
