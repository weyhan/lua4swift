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
            ("title", [], App.title),
        ]
    }
    
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<App>) {
        metaMethods.eq = { $0.app.pid == $1.app.pid }
    }
    
}
