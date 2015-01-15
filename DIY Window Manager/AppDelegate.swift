import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    let prefs = PreferencesController()
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        prefs.showWindow(nil)
    }
    
}
