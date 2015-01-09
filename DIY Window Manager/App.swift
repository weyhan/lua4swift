import Foundation
import Desktop
import Lua

extension Desktop.App: Lua.CustomTypeInstance {
    public class func luaTypeName() -> String { return "App" }
}

func appLib(vm: Lua.VirtualMachine) -> Lua.CustomType<Desktop.App> {
    return vm.createCustomType { [unowned vm] lib in
        
        // class methods
        
        lib["allApps"] = vm.createFunction([]) { _ in .Values(Desktop.App.allApps().map{vm.createUserdata($0)}) }
        lib["focusedApp"] = vm.createFunction([]) { _ in .Value(vm.createUserdataMaybe(Desktop.App.focusedApp())) }
        lib["appWithPid"] = vm.createFunction([Number.arg]) { args in
            let (pid) = (args.integer)
            return .Value(vm.createUserdataMaybe(Desktop.App(pid_t(pid))))
        }
        
        // instance methods
        
        lib["title"] = lib.createMethod([]) { app, _ in .Value(app.title()) }
        lib["quit"] = lib.createMethod([]) { app, _ in .Value(app.terminate())}
        lib["forceQuit"] = lib.createMethod([]) { app, _ in .Value(app.terminate(force: true)) }
        lib["hide"] = lib.createMethod([]) { app, _ in .Value(app.hide()) }
        lib["unhide"] = lib.createMethod([]) { app, _ in .Value(app.unhide()) }
        lib["isHidden"] = lib.createMethod([]) { app, _ in .Value(app.isHidden()) }
        lib["focusedWindow"] = lib.createMethod([]) { app, _ in .Value(vm.createUserdataMaybe(app.focusedWindow())) }
        lib["mainWindow"] = lib.createMethod([]) { app, _ in .Value(vm.createUserdataMaybe(app.mainWindow())) }
        
        lib.eq = { $0.pid == $1.pid }
        
    }
}
