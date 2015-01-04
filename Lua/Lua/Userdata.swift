import Foundation

public typealias UserdataPointer = UnsafeMutablePointer<Void>

public class Userdata: StoredValue {
    
    internal func toUserdataPointer() -> UserdataPointer {
        if vm == nil { return nil }
        
        return lua_touserdata(vm!.vm, -1)
    }
    
    public func toCustomType<T: CustomType>() -> T? {
        if vm == nil { return nil }
        
        let any = vm!.storedSwiftValues[toUserdataPointer()]
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
