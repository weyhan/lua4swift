import Foundation
import Desktop
import Lua

extension Desktop.Window: Lua.CustomType {
    public class func metatableName() -> String { return "Window" }
}

func windowLib(vm: Lua.VirtualMachine) -> Lua.Library<Desktop.Window> {
    return vm.createLibrary { [unowned vm] lib in
        
        lib["title"] = lib.createMethod([]) { win, _ in .Value(win.title()) }
        lib["topLeft"] = lib.createMethod([]) { win, _ in .Value(win.topLeft()) }
        lib["app"] = lib.createMethod([]) { win, _ in .Value(vm.createUserdataMaybe(win.app())) }
        
        lib["setTopLeft"] = lib.createMethod([.Table]) { win, args in
            let point = args.table
            if let p = point.toPoint() { win.setTopLeft(p) }
            return .Nothing
        }
        
        lib["allWindows"] = lib.createMethod([]) { win, _ in .Values(Desktop.Window.allWindows().map{vm.createUserdata($0)}) }
        lib["focusedWindow"] = lib.createMethod([]) { win, _ in .Value(vm.createUserdataMaybe(Desktop.Window.focusedWindow())) }
        
        lib.eq = { $0.id() == $1.id() }
        
    }
}
