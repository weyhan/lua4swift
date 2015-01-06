import Foundation
import Desktop
import Lua

extension Desktop.Window: Lua.CustomType {
    public class func metatableName() -> String { return "Window" }
}

func windowLib(vm: Lua.VirtualMachine) -> Lua.Library<Desktop.Window> {
    return vm.createLibrary { [unowned vm] lib in
        
        // class methods
        
        lib["allWindows"] = vm.createFunction([]) { _ in .Values(Desktop.Window.allWindows().map{vm.createUserdata($0)}) }
        lib["focusedWindow"] = vm.createFunction([]) { _ in .Value(vm.createUserdataMaybe(Desktop.Window.focusedWindow())) }
        
        // instance methods
        
        lib["title"] = lib.createMethod([]) { win, _ in .Value(win.title()) }
        lib["topLeft"] = lib.createMethod([]) { win, _ in .Value(win.topLeft()) }
        lib["app"] = lib.createMethod([]) { win, _ in .Value(vm.createUserdataMaybe(win.app())) }
        
        lib["setTopLeft"] = lib.createMethod([.Table]) { win, args in
            let point = args.table
            if let p = point.toPoint() { win.setTopLeft(p) }
            return .Nothing
        }
        
        lib["belongsToApp"] = lib.createMethod([.Userdata(Desktop.App.metatableName())]) { win, args in
            let app: Desktop.App = args.userdata.toCustomType()
            return .Value(win.app() == app)
        }
        
        lib.eq = { $0.id() == $1.id() }
        
    }
}
