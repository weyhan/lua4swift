import Foundation
import Desktop
import Lua

extension Desktop.Window: Lua.CustomTypeInstance {
    public class func luaTypeName() -> String { return "Window" }
}

func windowLib(vm: Lua.VirtualMachine) -> Lua.CustomType<Desktop.Window> {
    return vm.createCustomType { [unowned vm] lib in
        
        // class methods
        
        lib["allWindows"] = vm.createFunction([]) { _ in .Values(Desktop.Window.allWindows().map{vm.createUserdata($0)}) }
        lib["focusedWindow"] = vm.createFunction([]) { _ in .Value(vm.createUserdataMaybe(Desktop.Window.focusedWindow())) }
        
        // instance methods
        
        lib["title"] = lib.createMethod([]) { win, _ in .Value(win.title()) }
        lib["topLeft"] = lib.createMethod([]) { win, _ in .Value(win.topLeft()) }
        lib["app"] = lib.createMethod([]) { win, _ in .Value(vm.createUserdataMaybe(win.app())) }
        
        lib["setTopLeft"] = lib.createMethod([NSPoint.arg]) { win, args in .Value(win.setTopLeft(args.point)) }
        
        lib["belongsToApp"] = lib.createMethod([Lua.CustomType<Desktop.App>.arg]) { win, args in
            let (app: Desktop.App) = (args.customType())
            return .Value(win.app() == app)
        }
        
        lib.eq = { $0.id() == $1.id() }
        
    }
}
