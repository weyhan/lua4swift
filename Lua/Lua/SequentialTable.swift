import Foundation

public final class SequentialTable<T: Value>: Value {
    
    public var elements = [T]()
    
    public func pushValue(L: VirtualMachine) {
        L.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(L.vm, -1)) // overkill? dunno.
        for (i, value) in enumerate(elements) {
            Int64(i+1).pushValue(L)
            value.pushValue(L)
            L.setTable(tablePosition)
        }
    }
    
    public init?(fromLua L: VirtualMachine, var at position: Int) {
        position = L.absolutePosition(position) // pretty sure this is necessary
        var bag = [Int64:T]()
        
        L.pushNil()
        while lua_next(L.vm, Int32(position)) != 0 {
            let i = Int64(fromLua: L, at: -2)
            let val = T(fromLua: L, at: -1)
            L.pop(1)
            
            // non-int key or non-T value
            if i == nil || val == nil { return nil }
            
            bag[i!] = val!
        }
        
        if bag.count != 0 {
            // ensure table has no holes and keys start at 1
            let sortedKeys = sorted(bag.keys, <)
            if [Int64](1...sortedKeys.last!) != sortedKeys { return nil }
            
            for i in sortedKeys {
                self.elements.append(bag[i]!)
            }
        }
    }
    
    public subscript(index: Int) -> T { return elements[index] }
    
    public init(values: T...) {
        elements = values
    }
    
    public class func kind() -> Kind { return .Table }
    public class func typeName() -> String { return "array(\(T.typeName()))" }
    public class func arg() -> TypeChecker { return (SequentialTable<T>.typeName(), SequentialTable<T>.isValid) }
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
        return L.kind(position) == .Table && SequentialTable<T>(fromLua: L, at: position) != nil
    }
    
}
