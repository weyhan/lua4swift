import Foundation

final class SequentialTable<T: Value>: Value {
    
    var elements = [T]()
    
    func pushValue(L: VM) {
        L.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(L.L, -1)) // overkill? dunno.
        for (i, value) in enumerate(elements) {
            Int64(i+1).pushValue(L)
            value.pushValue(L)
            L.setTable(tablePosition)
        }
    }
    
    class func fromLua(L: VM, var at position: Int) -> SequentialTable<T>? {
        position = L.absolutePosition(position) // pretty sure this is necessary
        
        let array = SequentialTable<T>()
        var bag = [Int64:T]()
        
        L.pushNil()
        while lua_next(L.L, Int32(position)) != 0 {
            let i = Int64.fromLua(L, at: -2)
            let val = T.fromLua(L, at: -1)
            L.pop(1)
            
            // non-int key or non-T value
            if i == nil || val == nil { return nil }
            
            bag[i!] = val!
        }
        
        if bag.count == 0 { return array }
        
        // ensure table has no holes and keys start at 1
        let sortedKeys = sorted(bag.keys, <)
        if [Int64](1...sortedKeys.last!) != sortedKeys { return nil }
        
        for i in sortedKeys {
            array.elements.append(bag[i]!)
        }
        
        return array
    }
    
    subscript(index: Int) -> T { return elements[index] }
    
    init(values: T...) {
        elements = values
    }
    
    class func typeName() -> String { return "<Array of \(T.typeName())>" }
    class func kind() -> Kind { return .Table }
    class func arg() -> TypeChecker { return (SequentialTable<T>.typeName, SequentialTable<T>.isValid) }
    class func isValid(L: VM, at position: Int) -> Bool {
        return L.kind(position) == kind() && SequentialTable<T>.fromLua(L, at: position) != nil
    }
    
}
