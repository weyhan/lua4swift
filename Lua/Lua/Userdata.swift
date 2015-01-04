import Foundation

public typealias UserdataPointer = UnsafeMutablePointer<Void>

public class Userdata: StoredValue {
    
    internal var userdataPointer: UserdataPointer {
        push(vm)
        let ptr = lua_touserdata(vm.vm, -1)
        vm.pop()
        return ptr
    }
    
    public func toCustomType<T: CustomType>() -> T? {
        let any = vm.storedSwiftValues[userdataPointer]
        return any as? T
    }
    
    override public func kind() -> Kind { return .Userdata }
    
}

public class LightUserdata: StoredValue {
    
    override public func kind() -> Kind { return .LightUserdata }
    
}

public protocol CustomType {
    
    class func classMethods() -> [(String, (VirtualMachine, [Value]) -> SwiftReturnValue)]
    class func instanceMethods() -> [(String, Self -> (VirtualMachine, [Value]) -> SwiftReturnValue)]
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<Self>)
    class func metatableName() -> String
    
}

public struct MetaMethods<T> {
    
    internal init() {}
    public var gc: ((T, VirtualMachine) -> Void)?
    public var eq: ((T, T) -> Bool)?
    
}
