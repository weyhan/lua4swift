import Foundation

public enum Kind {
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
    
    public func toLuaType() -> Int32 {
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

extension VirtualMachine {
    
    public func kind(position: Int) -> Kind {
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
    
}
