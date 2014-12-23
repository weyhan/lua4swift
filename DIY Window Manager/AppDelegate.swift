import Cocoa
import Lua

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let L = Lua.VirtualMachine()
        
        
        L.pushCustomType(Hotkey)
        L.setGlobal("Hotkey")
        
        L.doString("Hotkey.bind(3)")
        L.doString("print(34 + 2)")
        L.doString("print(Hotkey)")
        L.doString("print(Hotkey.bind)")
        L.doString("print(Hotkey.__index)")
        L.doString("print(Hotkey.__index == Hotkey)")
        L.doString("k = Hotkey.bind('s', {'cmd', 'shift'}, function() print('ha') end)")
        L.doString("k:disable()")
        L.doString("k:enable()")
        
//        L.doString("Hotkey.bind('s', {'cmd', 'shift'}, function() print(3) end)")
        
//        NSApplication.sharedApplication().terminate(nil)
        
//        let hotkey = Hotkey(key: "s", mods: [Hotkey.Mod.Command, Hotkey.Mod.Shift]) { println("woo!") }
//        hotkey.enable()
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
//            hotkey.disable()
//            println("bla")
//        }
//        
//        return
        
//        let js = JavaScript()
//        
//        js["Window"] = JSWindow.self
//        js["Hotkey"] = JSHotkey.self
//        js["Utils"] = JSUtils.self
//        js.eval("print = Utils.print")
//        
//        println(js.eval("Hotkey"))
//        println(js.eval("Hotkey.bind"))
//        
//        println(js.eval("Hotkey.bind('s', ['cmd', 'shift'], function() { print('foo') })"))
//        println(js.eval("Window.focusedWindow().title()"))
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}
