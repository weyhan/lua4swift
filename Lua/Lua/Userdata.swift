import Foundation

public class Userdata: StoredValue {
    
    public func userdataPointer<T>() -> UnsafeMutablePointer<T> {
        push(vm)
        let ptr = lua_touserdata(vm.vm, -1)
        vm.pop()
        return UnsafeMutablePointer<T>(ptr)
    }
    
    public func toCustomType<T: CustomType>() -> T {
        return userdataPointer().memory
    }
    
    public func toAny() -> Any {
        return userdataPointer().memory
    }
    
    override public func kind() -> Kind { return .Userdata(nil) }
    
}

public class LightUserdata: StoredValue {
    
    override public func kind() -> Kind { return .LightUserdata }
    
}

public protocol CustomType {
    
    class func metatableName() -> String
    
}

public class Library<T: CustomType>: Table {
    
    override internal init(_ vm: VirtualMachine) {
        super.init(vm)
    }
    
    public var gc: ((T) -> Void)?
    public var eq: ((T, T) -> Bool)?
    
    public func createMethod(var kinds: [Kind], _ fn: (T, Arguments) -> SwiftReturnValue) -> Function {
        kinds.insert(.Userdata(T.metatableName()), atIndex: 0)
        return vm.createFunction(kinds) { (var args: Arguments) in
            let o: T = args.userdata.toCustomType()
            return fn(o, args)
        }
    }
    
}
