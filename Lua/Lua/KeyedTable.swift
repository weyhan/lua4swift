import Foundation

public final class KeyedTable<K: Value, T: Value where K: Hashable>: Value { // is there a less dumb way to write the generic signature here?
    
    public var elements = [K:T]()
    
    public func push(vm: VirtualMachine) {
        vm.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(vm.vm, -1)) // overkill? dunno.
        for (key, value) in elements {
            key.push(vm)
            value.push(vm)
            vm.setTable(tablePosition)
        }
    }
    
    public init?(fromLua vm: VirtualMachine, var at position: Int) {
        position = vm.absolutePosition(position) // pretty sure this is necessary
        
        vm.pushNil()
        while lua_next(vm.vm, Int32(position)) != 0 {
            let key = K(fromLua: vm, at: -2)
            let val = T(fromLua: vm, at: -1)
            vm.pop(1)
            
            // non-int key or non-T value
            if key == nil || val == nil { continue }
            
            self.elements[key!] = val!
        }
    }
    
    public subscript(key: K) -> T? { return elements[key] }
    
    public init() {}
    
    public init(_ values: [K:T]) {
        elements = values
    }
    
    public class func typeName() -> String { return "table(\(K.typeName()) : \(T.typeName()))" }
    public class func arg() -> TypeChecker { return (KeyedTable<K,T>.typeName(), KeyedTable<K,T>.isValid) }
    public class func isValid(vm: VirtualMachine, at position: Int) -> Bool {
        return vm.kind(position) == .Table && KeyedTable<K,T>(fromLua: vm, at: position) != nil
    }
    
}
