import Cocoa

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
