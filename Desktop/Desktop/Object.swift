import Cocoa

internal let systemWideElement = AXUIElementCreateSystemWide()!.takeRetainedValue()

public class Object: Equatable {
    
    public var element: AXUIElement!
    
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

public func ==(left: Object, right: Object) -> Bool {
    return CFEqual(left.element, right.element) != 0
}
