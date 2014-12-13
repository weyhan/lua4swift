import Foundation
import JavaScriptCore

@objc
private protocol JSWindowProtocol: JSExport {
    class func focusedWindow() -> JSWindow?
    func title() -> String?
}

@objc
class JSWindow: NSObject, JSWindowProtocol {
    let window: Accessibility.Window!
    
    init?(_ win: Accessibility.Window?) {
        super.init()
        if win == nil { return nil }
        window = win!
    }
    
    class func focusedWindow() -> JSWindow? {
        return JSWindow(Accessibility.Window.focusedWindow())
    }
    
    func title() -> String? {
        return window.title()
    }
}

class JavaScript {
    
    let vm = JSVirtualMachine()
    let ctx: JSContext
    
    init() {
        ctx = JSContext(virtualMachine: vm)
        ctx.exceptionHandler = self.handleException
    }
    
    func handleException(ctx: JSContext!, val: JSValue!) {
        println("js error: \(val)")
    }
    
    func eval(str: String) -> JSValue? {
        return self.ctx.evaluateScript(str)
    }
    
    subscript(key: NSObject?) -> AnyObject? {
        get { return self.ctx.objectForKeyedSubscript(key) }
        set { self.ctx.setObject(newValue, forKeyedSubscript: key) }
    }
    
}
