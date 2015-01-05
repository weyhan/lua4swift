import Foundation
import Desktop
import Lua

struct App: Lua.CustomType {
    
    let app: Desktop.App!
    
    static func metatableName() -> String { return "App" }
    
    init(_ app: Desktop.App) {
        self.app = app
    }
    
    init?(_ app: Desktop.App?) {
        if app == nil { return nil }
        self.app = app
    }
    
    func title(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.title())
    }
    
    func quit(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.terminate())
    }
    
    func forceQuit(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.terminate(force: true))
    }
    
    func hide(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.hide())
    }
    
    func unhide(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.unhide())
    }
    
    func isHidden(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(app.isHidden())
    }
    
    func focusedWindow(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(vm.createUserdataMaybe(Window(app.focusedWindow())))
    }
    
    func mainWindow(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(vm.createUserdataMaybe(Window(app.mainWindow())))
    }
    
    static func appWithPid(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        let pid = args[0] as Int64
        return .Value(vm.createUserdata(App(Desktop.App(pid_t(pid)))))
    }
    
    static func allApps(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Values(Desktop.App.allApps().map{vm.createUserdata(App($0))})
    }
    
    static func focusedApp(vm: Lua.VirtualMachine, args: [Lua.Value]) -> Lua.SwiftReturnValue {
        return .Value(vm.createUserdataMaybe(App(Desktop.App.focusedApp())))
    }
    
    static func classMethods() -> [(String, (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("appWithPid", App.appWithPid),
            ("allApps", App.allApps),
            ("focusedApp", App.focusedApp),
        ]
    }
    
    static func instanceMethods() -> [(String, App -> (Lua.VirtualMachine, [Lua.Value]) -> Lua.SwiftReturnValue)] {
        return [
            ("quit", App.quit),
            ("forceQuit", App.forceQuit),
            ("hide", App.hide),
            ("unhide", App.unhide),
            ("isHidden", App.isHidden),
            ("title", App.title),
            ("mainWindow", App.mainWindow),
            ("focusedWindow", App.focusedWindow),
        ]
    }
    
    static func setMetaMethods(inout metaMethods: Lua.MetaMethods<App>) {
        metaMethods.eq = { $0.app.pid == $1.app.pid }
    }
    
}
