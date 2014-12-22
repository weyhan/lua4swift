import Cocoa

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
