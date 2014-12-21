import Cocoa

class App: Object {
    
    var pid: pid_t {
        var pid: pid_t = 0
        AXUIElementGetPid(element, &pid)
        return pid
    }
    
    var app: NSRunningApplication? {
        return NSRunningApplication(processIdentifier: pid)?
    }
    
    convenience init(_ app: NSRunningApplication) {
        self.init(AXUIElementCreateApplication(app.processIdentifier).takeRetainedValue())
    }
    
    class func allApps() -> [App]? {
        return (NSWorkspace.sharedWorkspace().runningApplications as [NSRunningApplication]).map{ App($0) }
    }
    
    class func focusedApp() -> App? {
        return App(systemWideElement.getAttribute("AXFocusedApplication"))
    }
    
    func mainWindow() -> Window? {
        return Window(element.getAttribute("AXMainWindow"))
    }
    
    func focusedWindow() -> Window? {
        return Window(element.getAttribute(NSAccessibilityFocusedWindowAttribute))
    }
    
    func allWindows() -> [Window]? {
        return (element.getAttributes("AXWindows") as [AXUIElement]?)?.map{ Window($0) }
    }
    
    func activate(allWindows: Bool) -> Bool? {
        var opts = NSApplicationActivationOptions.ActivateIgnoringOtherApps
        if allWindows { opts |= .ActivateAllWindows }
        return app?.activateWithOptions(opts)
    }
    
    func isHidden() -> Bool? {
        return element.getAttribute(NSAccessibilityHiddenAttribute)
    }
    
    func terminate(force: Bool = false) -> Bool? {
        return force ? app?.forceTerminate() : app?.terminate()
    }
    
    func hide() -> Bool? {
        return element.setAttribute(NSAccessibilityHiddenAttribute, value: true)
    }
    
    func unhide() -> Bool? {
        return element.setAttribute(NSAccessibilityHiddenAttribute, value: false)
    }
    
}
