import Foundation
import Desktop
import Lua

class Thing1 {
    
    var handlers = Array<Desktop.AppEventHandler>()
    let fn: Desktop.AppEventHandler.Event
    
    private var appLaunchedWatcher: Desktop.DesktopEventHandler?
    private var appTerminatedWatcher: Desktop.DesktopEventHandler?
    
    init(fn: Desktop.AppEventHandler.Event) {
        self.fn = fn
    }
    
    func enable() {
        for app in Desktop.App.allApps() {
            if let handler = Desktop.AppEventHandler(app: app, event: fn) {
                let result = handler.enable()
                if result == nil {
                    handlers.append(handler)
                }
            }
        }
        
        appLaunchedWatcher = Desktop.DesktopEventHandler(.AppLaunched({ [weak self] app in
            if self == nil { return }
            
            println("app launched: \(app.title())")
            if let handler = Desktop.AppEventHandler(app: app, event: self!.fn) {
                let result = handler.enable()
                if result == nil {
                    println("creating window watcher for: \(app.title())")
                    self!.handlers.append(handler)
                }
            }
        }))
        
        appTerminatedWatcher = Desktop.DesktopEventHandler(.AppTerminated({ [weak self] app in
            if self == nil { return }
            
            self!.handlers = self!.handlers.filter{$0.app != app}
        }))
        
        appLaunchedWatcher?.enable()
        appTerminatedWatcher?.enable()
    }
    
    func disable() {
        appLaunchedWatcher?.disable()
        appTerminatedWatcher?.disable()
        for handler in handlers {
            handler.disable()
        }
    }
    
}


class Thing2 {
    
    var enable: (() -> ())?
    var disable: (() -> ())?
    
    init(_ fn: Desktop.AppEventHandler.Event) {
        var handlers = Array<Desktop.AppEventHandler>()
        
        self.enable = { [weak self] in
            for app in Desktop.App.allApps() {
                if let handler = Desktop.AppEventHandler(app: app, event: fn) {
                    let result = handler.enable()
                    if result == nil {
                        handlers.append(handler)
                    }
                }
            }
            
            let appLaunchedWatcher = Desktop.DesktopEventHandler(.AppLaunched({ app in
                println("app launched: \(app.title())")
                if let handler = Desktop.AppEventHandler(app: app, event: fn) {
                    let result = handler.enable()
                    if result == nil {
                        println("creating window watcher for: \(app.title())")
                        handlers.append(handler)
                    }
                }
            }))
            
            let appTerminatedWatcher = Desktop.DesktopEventHandler(.AppTerminated({ app in
                handlers = handlers.filter{$0.app != app}
            }))
            
            appLaunchedWatcher.enable()
            appTerminatedWatcher.enable()
            
            self?.disable = {
                appLaunchedWatcher.disable()
                appTerminatedWatcher.disable()
                for handler in handlers {
                    handler.disable()
                }
            }
        }
    }
    
    
}



final class Event: Lua.CustomType {
    
    class func metatableName() -> String { return "Event" }
    
    let fn: Int
    let f: Thing2
    
    init(fn: Int, f: Thing2) {
        self.fn = fn
        self.f = f
    }
    
    func enable(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        f.enable?()
        return .Nothing
    }
    
    func disable(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        f.disable?()
        return .Nothing
    }
    
    class func windowCreated(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        vm.pushFromStack(1)
        let fn = vm.ref(Lua.RegistryIndex)
        
        let f = Thing2(.WindowCreated({ win in
            println("window created: \(win.title()), in app: \(win.app()?.title())")
            vm.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
            Lua.UserdataBox(Window(win)).push(vm)
            vm.call(arguments: 1, returnValues: 0)
        }))
        
        f.enable?()
        
        return .Value(Lua.UserdataBox(Event(fn: fn, f: f)))
    }
    
    class func classMethods() -> [(String, [Lua.TypeChecker], Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
            ("windowCreated", [Lua.FunctionBox.arg()], Event.windowCreated),
        ]
    }
    
    class func instanceMethods() -> [(String, [Lua.TypeChecker], Event -> Lua.VirtualMachine -> Lua.ReturnValue)] {
        return [
        ]
    }
    
    class func setMetaMethods(inout metaMethods: Lua.MetaMethods<Event>) {
    }
    
}
