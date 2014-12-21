import Cocoa

let systemWideElement = AXUIElementCreateSystemWide()!.takeRetainedValue()

public extension AXUIElement {
    
    public func getAttribute<T>(property: String) -> T? {
        var ptr: Unmanaged<AnyObject>?
        if AXUIElementCopyAttributeValue(self, property, &ptr) != AXError(kAXErrorSuccess) { return nil }
        return ptr.map { $0.takeRetainedValue() as T }
    }
    
    public func getAttributes<T: AnyObject>(property: String) -> [T]? {
        var count: CFIndex = 0
        if AXUIElementGetAttributeValueCount(self, property, &count) != AXError(kAXErrorSuccess) { return nil }
        if count == 0 { return [T]() }
        
        var ptr: Unmanaged<CFArray>?
        if AXUIElementCopyAttributeValues(self, property, 0, count, &ptr) != AXError(kAXErrorSuccess) { return nil }
        if ptr == nil { return nil }
        
        let array: Array<AnyObject>? = ptr?.takeRetainedValue()
        if array == nil { return nil }
        return array as? [T]
    }
    
    public func setAttribute<T: AnyObject>(property: String, value: T) -> Bool {
        return AXUIElementSetAttributeValue(self, property, value) != AXError(kAXErrorSuccess)
    }
    
    public subscript(property: String) -> AnyObject? {
        get { return getAttribute(property) as AnyObject? }
        set { setAttribute(property, value: newValue!) }
    }
    
}

public extension AXValue {
    
    public class func fromPoint(var p: CGPoint) -> AXValue {
        return AXValueCreate(kAXValueCGPointType, &p).takeRetainedValue()
    }
    
    public class func fromSize(var p: CGSize) -> AXValue {
        return AXValueCreate(kAXValueCGSizeType, &p).takeRetainedValue()
    }
    
    public class func fromRect(var p: CGRect) -> AXValue {
        return AXValueCreate(kAXValueCGRectType, &p).takeRetainedValue()
    }
    
    public class func fromRange(var p: CFRange) -> AXValue {
        return AXValueCreate(kAXValueCFRangeType, &p).takeRetainedValue()
    }
    
    public func convertToStruct<T>() -> T? {
        let ptr = UnsafeMutablePointer<T>.alloc(1)
        let success = AXValueGetValue(self, AXValueGetType(self), ptr)
        let val = ptr.memory
        ptr.destroy()
        if success != 0 { return val }
        return nil
    }
    
}

public func ==(left: Object, right: Object) -> Bool {
    return CFEqual(left.element, right.element) != 0
}

public class Object: Equatable {
    
    var element: AXUIElement!
    
    public init?(_ el: AXUIElement?) {
        if el == nil { return nil }
        element = el
    }
    
    public init(_ el: AXUIElement) { element = el }
    
    public func title() -> String? {
        return element.getAttribute(NSAccessibilityTitleAttribute)
    }
    
    internal func subrole() -> String? {
        return element.getAttribute(NSAccessibilitySubroleAttribute)
    }
    
    internal func role() -> String? {
        return element.getAttribute(NSAccessibilityRoleAttribute)
    }
    
}

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
    
    public class func allApps() -> [App]? {
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

public class Window: Object {
    
    public class func focusedWindow() -> Window? {
        return App.focusedApp()?.focusedWindow()
    }
    
    public func topLeft() -> NSPoint? {
        return (element.getAttribute(NSAccessibilityPositionAttribute) as AXValue?)?.convertToStruct()
    }
    
    public func size() -> NSSize? {
        return (element.getAttribute(NSAccessibilitySizeAttribute) as AXValue?)?.convertToStruct()
    }
    
    public func frame() -> NSRect? {
        let p = topLeft()
        let s = size()
        if p == nil || s == nil { return nil }
        return NSRect(origin: p!, size: s!)
    }
    
    public func setTopLeft(p: NSPoint) -> Bool {
        return element.setAttribute(NSAccessibilityPositionAttribute, value: AXValue.fromPoint(p))
    }
    
    public func setSize(s: NSSize) -> Bool {
        return element.setAttribute(NSAccessibilitySizeAttribute, value: AXValue.fromSize(s))
    }
    
    public func setFrame(f: NSRect) -> Bool {
        return self.setSize(f.size) &&
            self.setTopLeft(f.origin) &&
            self.setSize(f.size)
    }
    
    public func isStandard() -> Bool? {
        return subrole()? == "AXStandardWindow"
    }
    
}
