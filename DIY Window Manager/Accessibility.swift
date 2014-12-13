import Cocoa

let systemWideElement = AXUIElementCreateSystemWide()!.takeRetainedValue()

extension AXUIElement {
    
    func getAttribute<T>(property: String) -> T? {
        var ptr: Unmanaged<AnyObject>?
        if AXUIElementCopyAttributeValue(self, property, &ptr) != AXError(kAXErrorSuccess) { return nil }
        return ptr.map { $0.takeRetainedValue() as T }
    }
    
    func getAttributes<T: AnyObject>(property: String) -> [T]? {
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
    
    func setAttribute<T: AnyObject>(property: String, value: T) -> Bool {
        return AXUIElementSetAttributeValue(self, property, value) != AXError(kAXErrorSuccess)
    }
    
    subscript(property: String) -> AnyObject? {
        get { return getAttribute(property) as AnyObject? }
        set { setAttribute(property, value: newValue!) }
    }
    
}

extension AXValue {
    
    class func fromPoint(var p: CGPoint) -> AXValue {
        return AXValueCreate(kAXValueCGPointType, &p).takeRetainedValue()
    }
    
    class func fromSize(var p: CGSize) -> AXValue {
        return AXValueCreate(kAXValueCGSizeType, &p).takeRetainedValue()
    }
    
    class func fromRect(var p: CGRect) -> AXValue {
        return AXValueCreate(kAXValueCGRectType, &p).takeRetainedValue()
    }
    
    class func fromRange(var p: CFRange) -> AXValue {
        return AXValueCreate(kAXValueCFRangeType, &p).takeRetainedValue()
    }
    
    func convertToStruct<T>() -> T? {
        let ptr = UnsafeMutablePointer<T>.alloc(1)
        let success = AXValueGetValue(self, AXValueGetType(self), ptr)
        let val = ptr.memory
        ptr.destroy()
        if success != 0 { return val }
        return nil
    }
    
}

func ==(left: Accessibility.Object, right: Accessibility.Object) -> Bool {
    return CFEqual(left.element, right.element) != 0
}

class Accessibility {
    
    class Object: Equatable {
        
        var element: AXUIElement!
        
        init?(_ el: AXUIElement?) {
            if el == nil { return nil }
            element = el
        }
        
        init(_ el: AXUIElement) { element = el }
        
        func title() -> String? {
            return element.getAttribute(NSAccessibilityTitleAttribute)
        }
        
        internal func subrole() -> String? {
            return element.getAttribute(NSAccessibilitySubroleAttribute)
        }
        
        internal func role() -> String? {
            return element.getAttribute(NSAccessibilityRoleAttribute)
        }
        
    }
    
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
    
    class Window: Object {
        
        class func focusedWindow() -> Window? {
            return App.focusedApp()?.focusedWindow()
        }
        
        func topLeft() -> NSPoint? {
            return (element.getAttribute(NSAccessibilityPositionAttribute) as AXValue?)?.convertToStruct()
        }
        
        func size() -> NSSize? {
            return (element.getAttribute(NSAccessibilitySizeAttribute) as AXValue?)?.convertToStruct()
        }
        
        func frame() -> NSRect? {
            let p = topLeft()
            let s = size()
            if p == nil || s == nil { return nil }
            return NSRect(origin: p!, size: s!)
        }
        
        func setTopLeft(p: NSPoint) -> Bool {
            return element.setAttribute(NSAccessibilityPositionAttribute, value: AXValue.fromPoint(p))
        }
        
        func setSize(s: NSSize) -> Bool {
            return element.setAttribute(NSAccessibilitySizeAttribute, value: AXValue.fromSize(s))
        }
        
        func setFrame(f: NSRect) -> Bool {
            return self.setSize(f.size) &&
                self.setTopLeft(f.origin) &&
                self.setSize(f.size)
        }
        
        func isStandard() -> Bool? {
            return subrole()? == "AXStandardWindow"
        }
        
    }
    
}
