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
