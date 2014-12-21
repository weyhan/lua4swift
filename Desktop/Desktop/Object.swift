import Cocoa

internal let systemWideElement = AXUIElementCreateSystemWide()!.takeRetainedValue()

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

func ==(left: Object, right: Object) -> Bool {
    return CFEqual(left.element, right.element) != 0
}
