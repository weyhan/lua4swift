import Foundation
import Desktop
import Lua

final class Window: Lua.CustomType {
    
    private let _win: Desktop.Window?
    var win: Desktop.Window { return _win! }
    
    class func metatableName() -> String { return "Window" }
    
    init(_ win: Desktop.Window) {
        _win = win
    }
    
    init?(_ win: Desktop.Window?) {
        if win == nil { return nil }
        _win = win
    }
    
    func title(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(win.title())
    }
    
    func topLeft(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(win.topLeft())
    }
    
    class func allWindows(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Values(Desktop.Window.allWindows().map{UserdataBox(Window($0))})
    }
    
    class func focusedWindow(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(Lua.UserdataBox(Window(Desktop.Window.focusedWindow())))
    }
    
    func equals(other: Window) -> Bool {
        return win.id() == other.win.id()
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("allWindows", [], Window.allWindows),
            ("focusedWindow", [], Window.focusedWindow),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Window -> Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("title", [], Window.title),
            ("topLeft", [], Window.topLeft),
        ]
    }
    
    class func metaMethods() -> [Lua.MetaMethod<Window>] {
        return [
            .EQ(Window.equals),
        ]
    }
    
}
