import Foundation

public class Table: StoredValue {
    
    public subscript(key: Value) -> Value {
        get {
            if vm == nil { return Nil() }
            
            push(vm!)
            
            key.push(vm!)
            lua_gettable(vm!.vm, -2)
            let v = vm!.value(-1)
            
            vm!.pop()
            return v!
        }
        
        set {
            if vm == nil { return }
            
            push(vm!)
            
            key.push(vm!)
            newValue.push(vm!)
            lua_settable(vm!.vm, -3)
            
            vm!.pop()
        }
    }
    
    override public func kind() -> Kind { return .Table }
    
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
