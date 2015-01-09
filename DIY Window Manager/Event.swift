import Foundation
import Desktop
import Lua

enum EventHandler: Lua.CustomType {
    
    case AllApps(Desktop.GlobalAppObserver)
    
    static func metatableName() -> String { return "Event" }
    
    func enable() {
        switch self {
        case let AllApps(e):
            e.enable()
        }
    }
    
    func disable() {
        switch self {
        case let AllApps(e):
            e.disable()
        }
    }
    
}

func eventLib(vm: Lua.VirtualMachine) -> Lua.Library<EventHandler> {
    return vm.createLibrary { [unowned vm] lib in
        
        // class methods
        
        func globalAppObserver(name: String, fn: Lua.Function -> Desktop.AppObserver.Callback) {
            lib[name] = vm.createFunction([Function.arg]) { args in
                let callbackFunction = args.function
                let observer = Desktop.GlobalAppObserver(fn(callbackFunction))
                observer.enable()
                return .Value(vm.createUserdata(EventHandler.AllApps(observer)))
            }
        }
        
        globalAppObserver("windowCreated") { fn in .WindowCreated({ win in fn.call([vm.createUserdata(win)]); return }) }
        globalAppObserver("windowDestroyed") { fn in .WindowDestroyed({ win in fn.call([vm.createUserdata(win)]); return }) }
        
        // instance methods
        
        lib["enable"] = lib.createMethod([]) { event, _ in
            event.enable()
            return .Nothing
        }
        
        lib["disable"] = lib.createMethod([]) { event, _ in
            event.disable()
            return .Nothing
        }
        
    }
}
