import Foundation

public class Table: StoredValue {
    
    public subscript(key: Value) -> Value {
        get {
            push(vm)
            
            key.push(vm)
            lua_gettable(vm.vm, -2)
            let v = vm.popValue(-1)
            
            vm.pop()
            return v!
        }
        
        set {
            push(vm)
            
            key.push(vm)
            newValue.push(vm)
            lua_settable(vm.vm, -3)
            
            vm.pop()
        }
    }
    
    public func keys() -> [Value] {
        var k = [Value]()
        push(vm) // table
        lua_pushnil(vm.vm)
        while lua_next(vm.vm, -2) != 0 {
            vm.pop() // val
            let key = vm.popValue(-1)!
            k.append(key)
            key.push(vm)
        }
        vm.pop() // table
        return k
    }
    
    public func values() -> [(Value, Value)] {
        var v = [(Value, Value)]()
        
        for key in keys() {
            let val = self[key]
            v.append((key, val))
        }
        
        return v
    }
    
    override public func kind() -> Kind { return .Table }
    
    public func asSequence<T: Value>() -> [T] {
        var array = [T]()
        
        let numericKeys = keys().map{$0 as? Int64}.filter{$0 != nil}.map{$0!}
        
        // if it has no numeric keys, then it's empty; job well done, team, job well done.
        if numericKeys.count == 0 { return array }
        
        // ensure table has no holes and keys start at 1
        let sortedKeys = sorted(numericKeys, <)
        if [Int64](1...sortedKeys.last!) != sortedKeys { return array }
        
        var bag = [Int64:T]()
        
        for i in sortedKeys {
            array.append(bag[i]!)
        }
        
//        for (key, val) in vals {
//            if key is Double && val is T {
//                let i = Int64(key as Double)
//                bag[i] = (val as T)
//            }
//        }
//        
        
        return array
    }
    
    func storeReference(v: Value) -> Int {
        v.push(vm)
        return vm.ref(RegistryIndex)
    }
    
    func removeReference(ref: Int) {
        vm.unref(RegistryIndex, ref)
    }
    
}


//public final class KeyedTable<K: Value, T: Value where K: Hashable>: Value { // is there a less dumb way to write the generic signature here?
//
//    public var elements = [K:T]()
//
//    public func push(vm: VirtualMachine) {
//        vm.pushTable(keyCapacity: elements.count)
//        let tablePosition = Int(lua_absindex(vm.vm, -1)) // overkill? dunno.
//        for (key, value) in elements {
//            key.push(vm)
//            value.push(vm)
//            vm.setTable(tablePosition)
//        }
//    }
//
//    public init?(fromLua vm: VirtualMachine, var at position: Int) {
//        position = vm.absolutePosition(position) // pretty sure this is necessary
//
//        vm.pushNil()
//        while lua_next(vm.vm, Int32(position)) != 0 {
//            let key = K(fromLua: vm, at: -2)
//            let val = T(fromLua: vm, at: -1)
//            vm.pop(1)
//
//            // non-int key or non-T value
//            if key == nil || val == nil { continue }
//
//            self.elements[key!] = val!
//        }
//    }
//
//    public subscript(key: K) -> T? { return elements[key] }
//
//    public init() {}
//
//    public init(_ values: [K:T]) {
//        elements = values
//    }
//
//    public class func typeName() -> String { return "table(\(K.typeName()) : \(T.typeName()))" }
//    public class func arg() -> TypeChecker { return (KeyedTable<K,T>.typeName(), KeyedTable<K,T>.isValid) }
//    public class func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Table && KeyedTable<K,T>(fromLua: vm, at: position) != nil
//    }
//
//}


//public final class SequentialTable<T: Value>: Value {
//
//    public var elements = [T]()
//
//    public func push(vm: VirtualMachine) {
//        vm.pushTable(keyCapacity: elements.count)
//        let tablePosition = Int(lua_absindex(vm.vm, -1)) // overkill? dunno.
//        for (i, value) in enumerate(elements) {
//            Int64(i+1).push(vm)
//            value.push(vm)
//            vm.setTable(tablePosition)
//        }
//    }
//
//    public init?(fromLua vm: VirtualMachine, var at position: Int) {
//        position = vm.absolutePosition(position) // pretty sure this is necessary
//        var bag = [Int64:T]()
//
//        vm.pushNil()
//        while lua_next(vm.vm, Int32(position)) != 0 {
//            let i = Int64(fromLua: vm, at: -2)
//            let val = T(fromLua: vm, at: -1)
//            vm.pop(1)
//
//            // non-int key or non-T value
//            if i == nil || val == nil { continue }
//
//            bag[i!] = val!
//        }
//
//        if bag.count != 0 {
//            // ensure table has no holes and keys start at 1
//            let sortedKeys = sorted(bag.keys, <)
//            if [Int64](1...sortedKeys.last!) != sortedKeys { return nil }
//
//            for i in sortedKeys {
//                self.elements.append(bag[i]!)
//            }
//        }
//    }
//
//    public subscript(index: Int) -> T { return elements[index] }
//
//    public init(values: T...) {
//        elements = values
//    }
//
//    public class func typeName() -> String { return "array(\(T.typeName()))" }
//    public class func arg() -> TypeChecker { return (SequentialTable<T>.typeName(), SequentialTable<T>.isValid) }
//    public class func isValid(vm: VirtualMachine, at position: Int) -> Bool {
//        return vm.kind(position) == .Table && SequentialTable<T>(fromLua: vm, at: position) != nil
//    }
//
//}
