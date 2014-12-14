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

@objc
private protocol JSHotkeyProtocol: JSExport {
    class func bind(key: NSString, mods: NSArray, downFn: JSValue) -> JSHotkey
    func enable()
}

@objc
class JSHotkey: NSObject, JSHotkeyProtocol {
    let hotkey: Hotkey!
    
    init(key: String, mods: [String], downFn: JSValue?) {
        super.init()
        
        let downCallback: Hotkey.Callback = {
            downFn?.callWithArguments([])
            return () // lol swift
        }
        
        hotkey = Hotkey(key: key, modStrings: mods, downFn: downCallback, upFn: nil)
    }
    
    class func bind(key: NSString, mods: NSArray, downFn: JSValue) -> JSHotkey {
        println("welp")
        let k = JSHotkey(key: key, mods: mods as [String], downFn: downFn)
        k.hotkey.enable()
        return k
    }
    
    func enable() {
        hotkey.enable()
    }
}

@objc
private protocol JSUtilsProtocol: JSExport {
    class func print(str: AnyObject)
}

@objc
class JSUtils: NSObject, JSUtilsProtocol {
    class func print(str: AnyObject) {
        println(str)
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
