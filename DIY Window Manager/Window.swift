import Foundation
import Desktop
import Lua

final class Window: Lua.CustomType {
    
    let win: Desktop.Window
    
    class func metatableName() -> String { return "Window" }
    
    init(_ win: Desktop.Window) {
        self.win = win
    }
    
    func title(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(win.title()!)
    }
    
    class func allWindows(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Values(Desktop.Window.allWindows().map{UserdataBox(Window($0))})
    }
    
    class func focusedWindow(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        if let win = Desktop.Window.focusedWindow() {
            return .Value(Lua.UserdataBox(Window(win)))
        }
        return .Value(Lua.Nil)
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
        ]
    }
    
    class func metaMethods() -> [Lua.MetaMethod<Window>] {
        return [
            .EQ(Window.equals),
        ]
    }
    
}
