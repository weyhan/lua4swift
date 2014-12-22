import Foundation

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
