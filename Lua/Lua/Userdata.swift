import Foundation

public protocol CustomType {
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)]
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Self -> Lua.VirtualMachine -> Lua.ReturnValue)]
    class func metaMethods() -> [MetaMethod<Self>]
    class func typeName() -> String
    
}

public enum MetaMethod<T> {
    case GC(T -> VirtualMachine -> Void)
    case EQ(T -> T -> Bool)
}

public final class UserdataBox<T: CustomType>: Value {
    
    let object: T?
    let ptr: UserdataPointer?
    
    public init(_ object: T) {
        self.object = object
    }
    
    public init?(fromLua L: VirtualMachine, at position: Int) {
        let box: UserdataBox<T> = L.getUserdata(position)!
        object = box.object
    }
    
    public func pushValue(L: VirtualMachine) {
//        if ptr == nil {
//            // it doesn't exist yet, so create it.
//            let userdata = UserdataPointer(lua_newuserdata(L.luaState, 1))
//            L.storedSwiftValues[userdata] = self
//        }
//        else {
//            // this is just a copy, so push the original.
//            // oh wait, we can't.
//        }
    }
    
    public class func typeName() -> String {
        return T.typeName()
    }
    
    public class func isValid(L: VirtualMachine, at position: Int) -> Bool {
//        if L.kind(position) != .Userdata { return false }
//        if let ud: UserdataBox<T> = L.getUserdata(position) { return true }
        return false
    }
    
    public class func arg() -> TypeChecker {
        return (UserdataBox.typeName, UserdataBox.isValid)
    }
    
}
