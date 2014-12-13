import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        Keycode.setup()
        
        return
        
        let js = JavaScript()
        
        js["Window"] = JSWindow.self
        println(js["Window"])
        println(js.eval("Window"))
        println(js.eval("Window.focusedWindow().title()"))
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}
