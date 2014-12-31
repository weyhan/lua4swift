import Foundation
import Desktop
import Lua

class Thing1 {
    
    var handlers = Array<Desktop.AppEventHandler>()
    let fn: Desktop.AppEventHandler.Event
    
    private var appLaunchedWatcher: Desktop.DesktopEventHandler?
    private var appTerminatedWatcher: Desktop.DesktopEventHandler?
    
    init(_ fn: Desktop.AppEventHandler.Event) {
        self.fn = fn
    }
    
    func watch(app: Desktop.App) {
        if let handler = Desktop.AppEventHandler(app: app, event: fn) {
            let result = handler.enable()
            if result == nil {
                println("creating window watcher for: \(app.title())")
                handlers.append(handler)
            }
        }
    }
    
    func enable() {
        if appLaunchedWatcher != nil { return }
        
        for app in Desktop.App.allApps() {
            watch(app)
        }
        
        appLaunchedWatcher = Desktop.DesktopEventHandler(.AppLaunched({ [weak self] app in
            println("app launched: \(app.title())")
            if self == nil { return }
            self!.watch(app)
        }))
        
        appTerminatedWatcher = Desktop.DesktopEventHandler(.AppTerminated({ [weak self] app in
            println("app died: \(app.title())") // TODO: title = nil
            if self == nil { return }
            
            for handler in self!.handlers.filter({$0.app == app}) {
                handler.disable()
            }
            
            self!.handlers = self!.handlers.filter{$0.app != app}
        }))
        
        appLaunchedWatcher?.enable()
        appTerminatedWatcher?.enable()
    }
    
    func disable() {
        appLaunchedWatcher?.disable()
        appTerminatedWatcher?.disable()
        appLaunchedWatcher = nil
        appTerminatedWatcher = nil
        
        for handler in handlers {
            handler.disable()
        }
        handlers = []
    }
    
}


final class Event: Lua.CustomType {
    
    class func metatableName() -> String { return "Event" }
    
    let fn: Int
    let f: Thing1
    
    init(fn: Int, f: Thing1) {
        self.fn = fn
        self.f = f
    }
    
    func enable(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        f.enable()
        return .Nothing
    }
    
    func disable(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        f.disable()
        return .Nothing
    }
    
    class func windowCreated(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        vm.pushFromStack(1)
        let fn = vm.ref(Lua.RegistryIndex)
        
        let f = Thing1(.WindowCreated({ win in
            println("window created: \(win.title()), in app: \(win.app()?.title())")
            vm.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
            Lua.UserdataBox(Window(win)).push(vm)
            vm.call(arguments: 1, returnValues: 0)
        }))
        
        f.enable()
        
        return .Value(Lua.UserdataBox(Event(fn: fn, f: f)))
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("windowCreated", [Lua.FunctionBox.arg()], Event.windowCreated),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Event -> Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("enable", [], Event.enable),
            ("disable", [], Event.disable),
        ]
    }
    
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<Event>) {
    }
    
}
