import Cocoa

public class App: Object {
    
    public var pid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return pid
    }
    
    public var app: NSRunningApplication? {
        return NSRunningApplication(processIdentifier: pid)?
    }
    
    public convenience init(_ app: NSRunningApplication) {
        self.init(AXUIElementCreateApplication(app.processIdentifier).takeRetainedValue())
    }
    
    public convenience init(_ pid: pid_t) {
        self.init(AXUIElementCreateApplication(pid).takeRetainedValue())
    }
    
    public class func allApps() -> [App] {
        return (NSWorkspace.sharedWorkspace().runningApplications as [NSRunningApplication]).map{ App($0) }
    }
    
    public class func focusedApp() -> App? {
        return App(systemWideElement.getAttribute("AXFocusedApplication"))
    }
    
    public func mainWindow() -> Window? {
        return Window(element.getAttribute("AXMainWindow"))
    }
    
    public func focusedWindow() -> Window? {
        return Window(element.getAttribute(NSAccessibilityFocusedWindowAttribute))
    }
    
    public func allWindows() -> [Window]? {
        return (element.getAttributes("AXWindows") as [AXUIElement]?)?.map{ Window($0) }
    }
    
    public override func title() -> String? {
        return app?.localizedName
    }
    
    public func activate(allWindows: Bool) -> Bool? {
        var opts = NSApplicationActivationOptions.ActivateIgnoringOtherApps
        if allWindows { opts |= .ActivateAllWindows }
        return app?.activateWithOptions(opts)
    }
    
    public func isHidden() -> Bool? {
        return element.getAttribute(NSAccessibilityHiddenAttribute)
    }
    
    public func terminate(force: Bool = false) -> Bool? {
        return force ? app?.forceTerminate() : app?.terminate()
    }
    
    public func hide() -> Bool? {
        return element.setAttribute(NSAccessibilityHiddenAttribute, value: true)
    }
    
    public func unhide() -> Bool? {
        return element.setAttribute(NSAccessibilityHiddenAttribute, value: false)
    }
    
}
