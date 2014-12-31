import Foundation
import Desktop
import Lua

private func listen(fn: Desktop.AppEventHandler.Event) -> () -> Void {
    var handlers = Array<Desktop.AppEventHandler>()
    
    for app in Desktop.App.allApps() {
        if let handler = Desktop.AppEventHandler(app: app, event: fn) {
            let result = handler.enable()
            println("here5 \(result)")
            if result == nil {
                handlers.append(handler)
            }
        }
    }
    
    let appLaunchedWatcher = Desktop.DesktopEventHandler(.AppLaunched({ app in
        if let handler = Desktop.AppEventHandler(app: app, event: fn) {
            println("here3")
            let result = handler.enable()
            println("here4 \(result)")
            if result == nil {
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
        let fn = vm.ref(1)
        
        let disable = listen(.WindowCreated({ win in
            println("here7")
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
