import Foundation
import Desktop
import Lua

private func listen(fn: Desktop.AppEventHandler.Event) -> () -> Void {
    var handlers = Array<Desktop.AppEventHandler>()
    
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
    
    return {
        appLaunchedWatcher.disable()
        appTerminatedWatcher.disable()
        for handler in handlers {
            handler.disable()
        }
    }
}

final class Event: Lua.CustomType {
    
    class func metatableName() -> String { return "Event" }
    
    let fn: Int
    let disable: () -> ()
    
    init(fn: Int, disable: () -> ()) {
        self.fn = fn
        self.disable = disable
    }
    
    class func windowCreated(vm: Lua.VirtualMachine) -> Lua.ReturnValue {
        vm.pushFromStack(1)
        let fn = vm.ref(Lua.RegistryIndex)
        
        let disable = listen(.WindowCreated({ win in
            println("window created: \(win.title()), in app: \(win.app()?.title())")
            vm.rawGet(tablePosition: Lua.RegistryIndex, index: fn)
            Lua.UserdataBox(Window(win)).push(vm)
            vm.call(arguments: 1, returnValues: 0)
        }))
        
        return .Value(Lua.UserdataBox(Event(fn: fn, disable: disable)))
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
