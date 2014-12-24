import Foundation

public final class KeyedTable<K: Value, T: Value where K: Hashable>: Value { // is there a less dumb way to write the generic signature here?
    
    public var elements = [K:T]()
    
    public func pushValue(L: VirtualMachine) {
        L.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(L.vm, -1)) // overkill? dunno.
        for (key, value) in elements {
            key.pushValue(L)
            value.pushValue(L)
            L.setTable(tablePosition)
        }
    }
    
    public init?(fromLua L: VirtualMachine, var at position: Int) {
        position = L.absolutePosition(position) // pretty sure this is necessary
        
        L.pushNil()
        while lua_next(L.vm, Int32(position)) != 0 {
            let key = K(fromLua: L, at: -2)
            let val = T(fromLua: L, at: -1)
            L.pop(1)
            
            // non-int key or non-T value
            if key == nil || val == nil { return nil }
            
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
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Table && KeyedTable<K,T>(fromLua: L, at: position) != nil
    }
    
}
