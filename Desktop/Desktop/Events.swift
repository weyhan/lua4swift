import Foundation

public class AppObserver {
    
    public enum Event {
        case WindowCreated(Window -> Void)
        case ElementDestroyed(Window -> Void)
        case WindowMoved(Window -> Void)
        case WindowResized(Window -> Void)
        case WindowMiniaturized(Window -> Void)
        case WindowDeminiaturized(Window -> Void)
        case ApplicationHidden(App -> Void)
        case ApplicationShown(App -> Void)
        case FocusedWindowChanged(Window -> Void)
        case ApplicationActivated(App -> Void)
        case MainWindowChanged(Window? -> Void)
        
        func name() -> String {
            switch self {
            case WindowCreated:        return "AXWindowCreated"
            case ElementDestroyed:     return "AXUIElementDestroyed"
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
        
        func call(element: AXUIElement!) {
            switch self {
            case let WindowCreated(fn):        fn(Window(element))
            case let ElementDestroyed(fn):     fn(Window(element))
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
    public let event: Event
    
    public init?(app: App, event: Event) {
        self.app = app
        self.event = event
        fn = { event.call($0) }
        
        var ob: Unmanaged<AXObserver>?
        if AXObserverCreate(app.pid, SDegutisObserverCallbackTrampoline(), &ob) != AXError(kAXErrorSuccess) { return nil }
        if ob == nil { return nil }
        observer = ob!.takeRetainedValue()
        
        AXObserverAddNotification(observer, app.element, event.name(), SDegutisVoidStarifyBlock(fn))
        CFRunLoopAddSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer).takeUnretainedValue(), kCFRunLoopDefaultMode)
    }
    
    public func unregister() {
        if observer == nil { return }
        CFRunLoopRemoveSource(CFRunLoopGetMain(), AXObserverGetRunLoopSource(observer).takeUnretainedValue(), kCFRunLoopDefaultMode)
        AXObserverRemoveNotification(observer, app.element, event.name())
        observer = nil
    }
    
    deinit {
        unregister()
    }
    
}
