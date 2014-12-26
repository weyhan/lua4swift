import Foundation
import Desktop
import Lua

final class App: Lua.CustomType {
    
    private let _app: Desktop.App?
    var app: Desktop.App { return _app! }
    
    class func metatableName() -> String { return "App" }
    
    init(_ win: Desktop.App) {
        _app = win
    }
    
    init?(_ win: Desktop.App?) {
        if win == nil { return nil }
        _app = win
    }
    
    func title(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.title())
    }
    
    func quit(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.terminate())
    }
    
    func forceQuit(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.terminate(force: true))
    }
    
    func hide(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.hide())
    }
    
    func unhide(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.unhide())
    }
    
    func isHidden(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.isHidden())
    }
    
    func focusedWindow(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(UserdataBox(Window(app.focusedWindow())))
    }
    
    func mainWindow(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(UserdataBox(Window(app.mainWindow())))
    }
    
    class func appWithPid(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        let pid = Int64(fromLua: vm, at: 1)!
        return .Value(Lua.UserdataBox(App(Desktop.App(pid_t(pid)))))
    }
    
    class func allApps(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Values(Desktop.App.allApps().map{UserdataBox(App($0))})
    }
    
    class func focusedApp(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(Lua.UserdataBox(App(Desktop.App.focusedApp())))
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("appWithPid", [Int64.arg()], App.appWithPid),
            ("allApps", [], App.allApps),
            ("focusedApp", [], App.focusedApp),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], App -> Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("quit", [], App.quit),
            ("forceQuit", [], App.forceQuit),
            ("hide", [], App.hide),
            ("unhide", [], App.unhide),
            ("isHidden", [], App.isHidden),
            ("title", [], App.title),
            ("mainWindow", [], App.mainWindow),
            ("focusedWindow", [], App.focusedWindow),
        ]
    }
    
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<App>) {
        metaMethods.eq = { $0.app.pid == $1.app.pid }
    }
    
}
