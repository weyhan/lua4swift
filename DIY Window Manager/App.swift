import Foundation
import Desktop
import Lua

extension Desktop.App: Lua.CustomType {
    public class func metatableName() -> String { return "App" }
}

func appLib(vm: Lua.VirtualMachine) -> Lua.Library<Desktop.App> {
    return vm.createLibrary { [unowned vm] lib in
        
        lib["title"] = lib.createMethod([]) { app, _ in .Value(app.title()) }
        lib["quit"] = lib.createMethod([]) { app, _ in .Value(app.terminate())}
        lib["forceQuit"] = lib.createMethod([]) { app, _ in .Value(app.terminate(force: true)) }
        lib["hide"] = lib.createMethod([]) { app, _ in .Value(app.hide()) }
        lib["unhide"] = lib.createMethod([]) { app, _ in .Value(app.unhide()) }
        lib["isHidden"] = lib.createMethod([]) { app, _ in .Value(app.isHidden()) }
        lib["focusedWindow"] = lib.createMethod([]) { app, _ in .Value(vm.createUserdataMaybe(app.focusedWindow())) }
        lib["mainWindow"] = lib.createMethod([]) { app, _ in .Value(vm.createUserdataMaybe(app.mainWindow())) }
        lib["allApps"] = lib.createMethod([]) { app, _ in .Values(Desktop.App.allApps().map{vm.createUserdata($0)}) }
        lib["focusedApp"] = lib.createMethod([]) { app, _ in .Value(vm.createUserdataMaybe(Desktop.App.focusedApp())) }
        lib["appWithPid"] = lib.createMethod([.Number]) { app, args in
            let pid = args.number
            return .Value(vm.createUserdataMaybe(Desktop.App(pid_t(pid.toInteger()))))
        }
        
        lib.eq = { $0.pid == $1.pid }
        
    }
}
