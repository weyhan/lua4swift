import Foundation
import Desktop
import Lua

struct Window: Lua.CustomType {
    
    let win: Desktop.Window!
    
    static func metatableName() -> String { return "Window" }
    
    init(_ win: Desktop.Window) {
        self.win = win
    }
    
    init?(_ win: Desktop.Window?) {
        if win == nil { return nil }
        self.win = win
    }
    
    func title(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(win.title())
    }
    
    func app(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(vm.createUserdataMaybe(App(win.app())))
    }
    
    func topLeft(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(win.topLeft())
    }
    
    func setTopLeft(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        if let point = (args[0] as Table).toPoint() {
            win.setTopLeft(point)
        }
        return .Nothing
    }
    
    static func allWindows(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Values(Desktop.Window.allWindows().map{vm.createUserdata(Window($0))})
    }
    
    static func focusedWindow(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(vm.createUserdataMaybe(Window(Desktop.Window.focusedWindow())))
    }
    
    static func classMethods() -> [(String, (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("allWindows", Window.allWindows),
            ("focusedWindow", Window.focusedWindow),
        ]
    }
    
    static func instanceMethods() -> [(String, Window -> (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("app", Window.app),
            ("title", Window.title),
            ("topLeft", Window.topLeft),
            ("setTopLeft", Window.setTopLeft),
        ]
    }
    
    static func setMetaMethods(inout metaMethods: Lua.MetaMethods<Window>) {
        metaMethods.eq = { $0.win.id() == $1.win.id() }
    }
    
}
