import Foundation

public class Userdata: StoredValue {
    
    public func userdataPointer<T>() -> UnsafeMutablePointer<T> {
        push(vm)
        let ptr = lua_touserdata(vm.vm, -1)
        vm.pop()
        return UnsafeMutablePointer<T>(ptr)
    }
    
    public func toCustomType<T: CustomTypeInstance>() -> T {
        return userdataPointer().memory
    }
    
    public func toAny() -> Any {
        return userdataPointer().memory
    }
    
    override public func kind() -> Kind { return .Userdata }
    
}

public class LightUserdata: StoredValue {
    
    override public func kind() -> Kind { return .LightUserdata }
    
    override public class func arg(vm: VirtualMachine, value: Value) -> String? {
        if value.kind() != .LightUserdata { return "light userdata" }
        return nil
    }
    
}

public protocol CustomTypeInstance {
    
    static func luaTypeName() -> String
    
}

public class CustomType<T: CustomTypeInstance>: Table {
    
    override public class func arg(vm: VirtualMachine, value: Value) -> String? {
        value.push(vm)
        let isLegit = luaL_testudata(vm.vm, -1, (T.luaTypeName() as NSString).UTF8String) != nil
        vm.pop()
        if !isLegit { return T.luaTypeName() }
        return nil
    }
    
    override internal init(_ vm: VirtualMachine) {
        super.init(vm)
    }
    
    public var gc: ((T) -> Void)?
    public var eq: ((T, T) -> Bool)?
    
    public func createMethod(var typeCheckers: [TypeChecker], _ fn: (T, Arguments) -> SwiftReturnValue) -> Function {
        typeCheckers.insert(CustomType<T>.arg, atIndex: 0)
        return vm.createFunction(typeCheckers) { (args: Arguments) in
            let o: T = args.customType()
            return fn(o, args)
        }
    }
    
}
