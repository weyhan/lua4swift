import Foundation

public class Table: StoredValue {
    
    public subscript(key: Value) -> Value {
        get {
            push(vm)
            
            key.push(vm)
            lua_gettable(vm.vm, -2)
            let v = vm.value(-1)
            
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
    
}
