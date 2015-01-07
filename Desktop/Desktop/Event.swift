import Foundation

public class DesktopObserver {
    
    public enum Callback {
        case AppLaunched(App -> Void)
        case AppTerminated(App -> Void)
        case AppHidden(App -> Void)
        case AppUnhidden(App -> Void)
        case AppFocused(App -> Void)
        case AppUnfocused(App -> Void)
        
        private func name() -> String {
            switch self {
            case AppLaunched: return NSWorkspaceDidLaunchApplicationNotification
            case AppTerminated: return NSWorkspaceDidTerminateApplicationNotification
            case AppHidden: return NSWorkspaceDidHideApplicationNotification
            case AppUnhidden: return NSWorkspaceDidUnhideApplicationNotification
            case AppFocused: return NSWorkspaceDidActivateApplicationNotification
            case AppUnfocused: return NSWorkspaceDidDeactivateApplicationNotification
            }
        }
        
        private func call(fn: App -> Void, withUserInfo dict: AnyObject) {
            if let app = dict[NSWorkspaceApplicationKey] as? NSRunningApplication {
                fn(App(app))
            }
        }
        
        private func call(dict: AnyObject) {
            switch self {
            case let AppLaunched(fn): call(fn, withUserInfo: dict)
            case let AppTerminated(fn): call(fn, withUserInfo: dict)
            case let AppHidden(fn): call(fn, withUserInfo: dict)
            case let AppUnhidden(fn): call(fn, withUserInfo: dict)
            case let AppFocused(fn): call(fn, withUserInfo: dict)
            case let AppUnfocused(fn): call(fn, withUserInfo: dict)
            }
        }
    }
    
    private var observer: NSObjectProtocol?
    public let event: Callback
    
    public init(_ event: Callback) {
        self.event = event
    }
    
    public func enable() {
        observer = NSWorkspace.sharedWorkspace().notificationCenter.addObserverForName(event.name(), object: nil, queue: NSOperationQueue.mainQueue()) { [weak self] notification in
            if let dict = notification.userInfo {
                self?.event.call(dict)
            }
        }
    }
    
    public func disable() {
        if let o = observer {
            NSWorkspace.sharedWorkspace().notificationCenter.removeObserver(o)
            observer = nil
        }
    }
    
    deinit {
        disable()
    }
    
}

public class AppObserver {
    
    public enum Callback {
        case WindowCreated(Window -> Void)
        case WindowDestroyed(Window -> Void)
        case WindowMoved(Window -> Void)
        case WindowResized(Window -> Void)
        case WindowMiniaturized(Window -> Void)
        case WindowDeminiaturized(Window -> Void)
        case ApplicationHidden(App -> Void)
        case ApplicationShown(App -> Void)
        case FocusedWindowChanged(Window -> Void)
        case ApplicationActivated(App -> Void)
        case MainWindowChanged(Window? -> Void)
        
        private func name() -> String {
            switch self {
            case WindowCreated:        return "AXWindowCreated"
            case WindowDestroyed:     return "AXUIElementDestroyed"
            case WindowMoved:          return "AXWindowMoved"
            case WindowResized:        return "AXWindowResized"
            case WindowMiniaturized:   return "AXWindowMiniaturized"
            case WindowDeminiaturized: return "AXWindowDeminiaturized"
            case ApplicationHidden:    return "AXApplicationHidden"
            case ApplicationShown:     return "AXApplicationShown"
            case FocusedWindowChanged: return "AXFocusedWindowChanged"
            case ApplicationActivated: return "AXApplicationActivated"
            case MainWindowChanged:    return "AXMainWindowChanged"
            }
        }
        
        private func call(element: AXUIElement!) {
            switch self {
            case let WindowCreated(fn):        fn(Window(element))
            case let WindowDestroyed(fn):      fn(Window(element))
            case let WindowMoved(fn):          fn(Window(element))
            case let WindowResized(fn):        fn(Window(element))
            case let WindowMiniaturized(fn):   fn(Window(element))
            case let WindowDeminiaturized(fn): fn(Window(element))
            case let ApplicationHidden(fn):    fn(App(element))
            case let ApplicationShown(fn):     fn(App(element))
            case let FocusedWindowChanged(fn): fn(Window(element))
            case let ApplicationActivated(fn): fn(App(element))
            case let MainWindowChanged(fn):    fn(Window(element))
            }
        }
    }
    
    private var observer: AXObserver?
    private let fn: AXUIElement! -> Void
    public let app: App
    public let event: Callback
    
    public init?(app: App, event: Callback) {
        self.app = app
        self.event = event
        fn = { event.call($0) }
    }
    
    public func enable() -> String? {
        if observer != nil { return "Already enabled." }
        
        var ob: Unmanaged<AXObserver>?
        let result = AXObserverCreate(app.pid, SDegutisObserverCallbackTrampoline(), &ob)
        if result != AXError(kAXErrorSuccess) { return "AXObserverCreate failed: code \(result)" }
        if ob == nil { return "AXObserverCreate didn't do its job right" }
        observer = ob!.takeRetainedValue()
        
        AXObserverAddNotification(observer, app.element, event.name(), SDegutisVoidStarifyBlock(fn))
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer).takeUnretainedValue(), kCFRunLoopDefaultMode)
        
        return nil
    }
    
    public func disable() {
        if observer == nil { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer).takeUnretainedValue(), kCFRunLoopDefaultMode)
        AXObserverRemoveNotification(observer, app.element, event.name())
        observer = nil
    }
    
    deinit {
        disable()
    }
    
}

public class GlobalAppObserver {
    
    var handlers = Array<Desktop.AppObserver>()
    let fn: Desktop.AppObserver.Callback
    
    private var appLaunchedWatcher: Desktop.DesktopObserver?
    private var appTerminatedWatcher: Desktop.DesktopObserver?
    
    public init(_ fn: Desktop.AppObserver.Callback) {
        self.fn = fn
    }
    
    deinit {
        disable()
    }
    
    private func watch(app: Desktop.App) {
        if let handler = Desktop.AppObserver(app: app, event: fn) {
            let result = handler.enable()
            if result == nil {
                handlers.append(handler)
            }
        }
    }
    
    public func enable() {
        if appLaunchedWatcher != nil { return }
        
        for app in Desktop.App.allApps() {
            watch(app)
        }
        
        appLaunchedWatcher = Desktop.DesktopObserver(.AppLaunched({ [unowned self] app in
            self.watch(app)
        }))
        
        appTerminatedWatcher = Desktop.DesktopObserver(.AppTerminated({ [unowned self] app in
            for handler in self.handlers.filter({$0.app == app}) {
                handler.disable()
            }
            
            self.handlers = self.handlers.filter{$0.app != app}
        }))
        
        appTerminatedWatcher?.enable()
        appLaunchedWatcher?.enable()
    }
    
    public func disable() {
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
