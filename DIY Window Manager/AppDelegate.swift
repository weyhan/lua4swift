import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        let js = JavaScript()
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
            println(js.ctx.evaluateScript("Window.focusedWindow()"))
        }
        
        js.ctx.setObject(JSWindow.self, forKeyedSubscript: "Window")
//        js.ctx.evaluateScript("k.thing = 9")
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}
