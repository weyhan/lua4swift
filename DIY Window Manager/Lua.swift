import Foundation

import Cocoa

typealias LuaTypeChecker = (Lua.Kind, () -> String, (Lua, Int) -> Bool)

protocol LuaValue {
    func pushValue(L: Lua)
    class func fromLua(L: Lua, at position: Int) -> Self?
    class func typeName() -> String
    class func kind() -> Lua.Kind
    class func isValid(Lua, Int) -> Bool
    class func arg() -> LuaTypeChecker
}

protocol LuaLibrary: LuaValue {
    class func classMethods() -> [(String, [LuaTypeChecker], Lua -> [LuaValue])]
    class func instanceMethods() -> [(String, [LuaTypeChecker], Self -> Lua -> [LuaValue])]
    class func metaMethods() -> [LuaMetaMethod<Self>]
    class var metatableName: String { get }
}

enum LuaMetaMethod<T> {
    case GC(T -> Lua -> Void)
    case EQ(T -> T -> Bool)
}

extension NSPoint: LuaValue {
    func pushValue(L: Lua) {
        LuaDictionary<String,Double>(["x":Double(self.x), "y":Double(self.y)]).pushValue(L)
    }
    static func fromLua(L: Lua, at position: Int) -> NSPoint? {
        let table = LuaDictionary<String, Double>.fromLua(L, at: position)
        if table == nil { return nil }
        let x = table!["x"] ?? 0
        let y = table!["y"] ?? 0
        return NSPoint(x: x, y: y)
    }
    static func typeName() -> String { return "<Point>" }
    static func kind() -> Lua.Kind { return .Table }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (NSPoint.kind(), NSPoint.typeName, NSPoint.isValid) }
}

extension String: LuaValue {
    func pushValue(L: Lua) { L.pushString(self) }
    static func fromLua(L: Lua, at position: Int) -> String? {
        if L.kind(position) != .String { return nil }
        var len: UInt = 0
        let str = lua_tolstring(L.L, Int32(position), &len)
        return NSString(CString: str, encoding: NSUTF8StringEncoding)
    }
    static func typeName() -> String { return "<String>" }
    static func kind() -> Lua.Kind { return .String }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (String.kind(), String.typeName, String.isValid) }
}

extension Int64: LuaValue {
    func pushValue(L: Lua) { L.pushInteger(self) }
    static func fromLua(L: Lua, at position: Int) -> Int64? {
        if L.kind(position) != .Integer { return nil }
        return lua_tointegerx(L.L, Int32(position), nil)
    }
    static func typeName() -> String { return "<Integer>" }
    static func kind() -> Lua.Kind { return .Integer }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (Int64.kind(), Int64.typeName, Int64.isValid) }
}

extension Double: LuaValue {
    func pushValue(L: Lua) { L.pushDouble(self) }
    static func fromLua(L: Lua, at position: Int) -> Double? {
        if L.kind(position) != .Double { return nil }
        return lua_tonumberx(L.L, Int32(position), nil)
    }
    static func typeName() -> String { return "<Double>" }
    static func kind() -> Lua.Kind { return .Double }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (Double.kind(), Double.typeName, Double.isValid) }
}

extension Bool: LuaValue {
    func pushValue(L: Lua) { L.pushBool(self) }
    static func fromLua(L: Lua, at position: Int) -> Bool? {
        if L.kind(position) != .Bool { return nil }
        return lua_toboolean(L.L, Int32(position)) != 0
    }
    static func typeName() -> String { return "<Boolean>" }
    static func kind() -> Lua.Kind { return .Bool }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (Bool.kind(), Bool.typeName, Bool.isValid) }
}

extension Lua.FunctionBox: LuaValue {
    func pushValue(L: Lua) { L.pushFunction(self.fn) }
    static func fromLua(L: Lua, at position: Int) -> Lua.FunctionBox? {
        // can't ever convert functions to a usable object
        return nil
    }
    static func typeName() -> String { return "<Function>" }
    static func kind() -> Lua.Kind { return .Function }
    static func isValid(Lua, Int) -> Bool { return false }
    static func arg() -> LuaTypeChecker { return (Lua.FunctionBox.kind(), Lua.FunctionBox.typeName, Lua.FunctionBox.isValid) }
}

final class LuaArray<T: LuaValue>: LuaValue {
    
    var elements = [T]()
    
    func pushValue(L: Lua) {
        L.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(L.L, -1)) // overkill? dunno.
        for (i, value) in enumerate(elements) {
            Int64(i+1).pushValue(L)
            value.pushValue(L)
            L.setTable(tablePosition)
        }
    }
    
    class func fromLua(L: Lua, var at position: Int) -> LuaArray<T>? {
        position = L.absolutePosition(position) // pretty sure this is necessary
        
        let array = LuaArray<T>()
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
    class func kind() -> Lua.Kind { return .Table }
    class func isValid(Lua, Int) -> Bool { return false }
    class func arg() -> LuaTypeChecker { return (LuaArray<T>.kind(), LuaArray<T>.typeName, LuaArray<T>.isValid) }
    
}

final class LuaDictionary<K: LuaValue, T: LuaValue where K: Hashable>: LuaValue { // is there a less dumb way to write the generic signature here?
    
    var elements = [K:T]()
    
    func pushValue(L: Lua) {
        L.pushTable(keyCapacity: elements.count)
        let tablePosition = Int(lua_absindex(L.L, -1)) // overkill? dunno.
        for (key, value) in elements {
            key.pushValue(L)
            value.pushValue(L)
            L.setTable(tablePosition)
        }
    }
    
    class func fromLua(L: Lua, var at position: Int) -> LuaDictionary<K, T>? {
        position = L.absolutePosition(position) // pretty sure this is necessary
        
        var dict = LuaDictionary<K, T>()
        
        L.pushNil()
        while lua_next(L.L, Int32(position)) != 0 {
            let key = K.fromLua(L, at: -2)
            let val = T.fromLua(L, at: -1)
            L.pop(1)
            
            // non-int key or non-T value
            if key == nil || val == nil { return nil }
            
            dict.elements[key!] = val!
        }
        
        return dict
    }
    
    subscript(key: K) -> T? { return elements[key] }
    
    init() {}
    
    init(_ values: [K:T]) {
        elements = values
    }
    
    class func typeName() -> String { return "<Dictionary of \(K.typeName()) : \(T.typeName())>" }
    class func kind() -> Lua.Kind { return .Table }
    class func isValid(Lua, Int) -> Bool { return false }
    class func arg() -> LuaTypeChecker { return (LuaDictionary<K,T>.kind(), LuaDictionary<K,T>.typeName, LuaDictionary<K,T>.isValid) }
    
}

final class LuaNilType: LuaValue {
    func pushValue(L: Lua) { L.pushNil() }
    class func fromLua(L: Lua, at position: Int) -> LuaNilType? {
        if L.kind(position) != .Nil { return nil }
        return LuaNil
    }
    class func typeName() -> String { return "<nil>" }
    class func kind() -> Lua.Kind { return .Nil }
    class func isValid(Lua, Int) -> Bool { return false }
    class func arg() -> LuaTypeChecker { return (LuaNilType.kind(), LuaNilType.typeName, LuaNilType.isValid) }
}

let LuaNil = LuaNilType()

// basics
class Lua {
    
    let L = luaL_newstate()
    
    // meant for putting functions into Lua only; can't take them out
    struct FunctionBox {
        let fn: Function
        init(_ fn: Function) { self.fn = fn }
    }
    
    typealias Function = () -> [LuaValue]
    
    typealias UserdataPointer = UnsafeMutablePointer<Void>
    var storedSwiftValues = [UserdataPointer : Any]()
    
    init(openLibs: Bool = true) {
        if openLibs { luaL_openlibs(L) }
    }
    
}

// execute
extension Lua {
    
    func loadString(str: String) { luaL_loadstring(L, (str as NSString).UTF8String) }
    
    func doString(str: String) {
        loadString(str)
        call(arguments: 0, returnValues: Int(LUA_MULTRET))
    }
    
    func call(arguments: Int = 0, returnValues: Int = 0) {
        lua_pcallk(L, Int32(arguments), Int32(returnValues), 0, 0, nil)
    }
    
}

// set
extension Lua {
    
    func setGlobal(name: String) { lua_setglobal(L, (name as NSString).UTF8String) }
    func setField(name: String, table: Int) { lua_setfield(L, Int32(table), (name as NSString).UTF8String) }
    func setTable(tablePosition: Int) { lua_settable(L, Int32(tablePosition)) }
    func setMetatable(position: Int) { lua_setmetatable(L, Int32(position)) }
    
}

// get
extension Lua {
    
    func kind(position: Int) -> Kind {
        switch lua_type(L, Int32(position)) {
        case LUA_TNIL: return .Nil
        case LUA_TBOOLEAN: return .Bool
        case LUA_TNUMBER: return lua_isinteger(L, Int32(position)) == 0 ? .Double : .Integer
        case LUA_TSTRING: return .String
        case LUA_TFUNCTION: return .Function
        case LUA_TTABLE: return .Table
        case LUA_TUSERDATA, LUA_TLIGHTUSERDATA: return .Userdata
        case LUA_TTHREAD: return .Thread
        default: return .None
        }
    }
    
    func getUserdataPointer(position: Int) -> UserdataPointer? {
        if lua_type(L, Int32(position)) != LUA_TUSERDATA { return nil }
        return lua_touserdata(L, Int32(position))
    }
    
    func getUserdata(position: Int) -> LuaValue? {
        if lua_type(L, Int32(position)) != LUA_TUSERDATA { return nil }
        return UnsafeMutablePointer<LuaValue>(getUserdataPointer(position)!).memory
    }
    
    func isTruthy(position: Int) -> Bool {
        return lua_toboolean(L, Int32(position)) != 0
    }
    
}

// push
extension Lua {
    
    func pushTable(sequenceCapacity: Int = 0, keyCapacity: Int = 0) {
        lua_createtable(L, Int32(sequenceCapacity), Int32(keyCapacity))
    }
    
    func pushNil()             { lua_pushnil(L) }
    func pushBool(value: Bool) { lua_pushboolean(L, value ? 1 : 0) }
    func pushDouble(n: Double) { lua_pushnumber(L, n) }
    func pushInteger(n: Int64) { lua_pushinteger(L, n) }
    func pushString(s: String) { lua_pushstring(L, (s as NSString).UTF8String) }
    
    func pushFunction(fn: Function, upvalues: Int = 0) {
        let f: @objc_block (COpaquePointer) -> Int32 = { _ in
            let results = fn()
            for result in results { result.pushValue(self) }
            return Int32(results.count)
        }
        let block: AnyObject = unsafeBitCast(f, AnyObject.self)
        let imp = imp_implementationWithBlock(block)
        let fp = CFunctionPointer<(COpaquePointer) -> Int32>(imp)
        lua_pushcclosure(L, fp, Int32(upvalues))
    }
    
    func pushMethod(name: String, _ types: [LuaTypeChecker], _ fn: Function, tablePosition: Int = -1) {
        pushString(name)
        pushFunction {
            for (i, (kind, nameFn, testFn)) in enumerate(types) {
                luaL_checktype(self.L, Int32(i+1), kind.toLuaType())
                
                if !testFn(self, i+1) {
                    luaL_argerror(self.L, Int32(i+1), ("\(nameFn()) expected, got <TODO>" as NSString).UTF8String)
                }
                
//                switch t {
////                case let .Userdata(u) where u != nil:
////                    luaL_checkudata(self.L, Int32(i+1), u!)
//                default:
//                }
            }
            
            return fn()
        }
        setTable(tablePosition - 2)
    }
    
    func pushInstanceMethod<T: LuaLibrary>(name: String, var _ types: [LuaTypeChecker], _ fn: T -> Lua -> [LuaValue], tablePosition: Int = -1) {
        types.insert(T.arg(), atIndex: 0)
        let f: Function = {
            let o = T.fromLua(self, at: 1)!
            return fn(o)(self)
        }
        pushMethod(name, types, f, tablePosition: tablePosition)
    }
    
    func pushClassMethod(name: String, var _ types: [LuaTypeChecker], _ fn: Lua -> [LuaValue], tablePosition: Int = -1) {
        pushMethod(name, types, { fn(self) }, tablePosition: tablePosition)
    }
    
    func pushFromStack(position: Int) {
        lua_pushvalue(L, Int32(position))
    }
    
    func pop(n: Int) {
        lua_settop(L, -Int32(n)-1)
    }
    
    func pushField(name: String, fromTable: Int) {
        lua_getfield(L, Int32(fromTable), (name as NSString).UTF8String)
    }
    
    func pushUserdata<T>(swiftObject: T) {
        let userdata = UnsafeMutablePointer<T>(lua_newuserdata(L, UInt(sizeof(T))))
        userdata.memory = swiftObject
        storedSwiftValues[userdata] = swiftObject
    }
    
    func pushMetaMethod<T: LuaLibrary>(metaMethod: LuaMetaMethod<T>) {
        switch metaMethod {
        case let .GC(fn):
            pushMethod("__gc", [T.arg()]) {
                fn(T.fromLua(self, at: 1)!)(self)
                self.storedSwiftValues[self.getUserdataPointer(1)!] = nil
                return []
            }
        case let .EQ(fn):
            pushMethod("__eq", [T.arg(), T.arg()]) {
                let a = T.fromLua(self, at: 1)!
                let b = T.fromLua(self, at: 2)!
                return [fn(a)(b)]
            }
        }
    }
    
    func pushLibrary<T: LuaLibrary>(t: T.Type) {
        pushTable()
        
        // Registry.T = lib
        pushFromStack(-1)
        setField(T.metatableName, table: Lua.RegistryIndex)
        
        // setmetatable(lib, lib)
        pushFromStack(-1)
        setMetatable(-2)
        
        // lib.__index == lib
        pushFromStack(-1)
        setField("__index", table: -2)
        
        for mm in t.metaMethods() {
            pushMetaMethod(mm)
        }
        
        for (name, kinds, fn) in t.classMethods() {
            pushClassMethod(name, kinds, fn)
        }
        
        for (name, kinds, fn) in t.instanceMethods() {
            pushInstanceMethod(name, kinds, fn)
        }
    }
    
}

// ref
extension Lua {
    
    class var RegistryIndex: Int { return Int(SDegutisLuaRegistryIndex) } // ugh swift
    
    func ref(position: Int) -> Int { return Int(luaL_ref(L, Int32(position))) }
    func unref(table: Int, _ position: Int) { luaL_unref(L, Int32(table), Int32(position)) }
    
}

// uhh, misc?
extension Lua {
    
    func absolutePosition(position: Int) -> Int { return Int(lua_absindex(L, Int32(position))) }
    
}

// raw
extension Lua {
    
    func rawGet(#tablePosition: Int, index: Int) {
        lua_rawgeti(L, Int32(tablePosition), lua_Integer(index))
    }
    
}

// type checking
extension Lua {
    
    enum Kind {
        case String
        case Double
        case Integer
        case Bool
        case Function
        case Table
        case Userdata
        case Thread
        case Nil
        case None
        
        func toLuaType() -> Int32 {
            switch self {
            case String: return LUA_TSTRING
            case Double: return LUA_TNUMBER
            case Integer: return LUA_TNUMBER
            case Bool: return LUA_TBOOLEAN
            case Function: return LUA_TFUNCTION
            case Table: return LUA_TTABLE
            case Userdata: return LUA_TUSERDATA
            case Thread: return LUA_TTHREAD
            case Nil: return LUA_TNIL
            default: return LUA_TNONE
            }
        }
    }
    
}
