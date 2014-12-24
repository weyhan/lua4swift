import Foundation
import Desktop
import Lua

final class App: Lua.CustomType {
    
    let app: Desktop.App
    
    class func metatableName() -> String { return "App" }
    
    init(_ win: Desktop.App) {
        self.app = win
    }
    
    func title(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Value(app.title()!)
    }
    
    class func allApps(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        return .Values(Desktop.App.allApps().map{UserdataBox(App($0))})
    }
    
    class func focusedApp(L: Lua.VirtualMachine) -> Lua.ReturnValue {
        if let win = Desktop.App.focusedApp() {
            return .Value(Lua.UserdataBox(App(win)))
        }
        return .Value(Lua.Nil)
    }
    
    func equals(other: App) -> Bool {
        return app.pid == other.app.pid
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("allApps", [], App.allApps),
            ("focusedApp", [], App.focusedApp),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], App -> Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("title", [], App.title),
        ]
    }
    
    class func metaMethods() -> [Lua.MetaMethod<App>] {
        return [
            .EQ(App.equals),
        ]
    }
    
}
