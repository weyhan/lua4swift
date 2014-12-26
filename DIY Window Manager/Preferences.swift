import Cocoa

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var checkbox: NSButton!
    
    override var windowNibName: String? { return "Preferences" }
    
    @IBAction func clickCheckbox(sender: NSButton?) {
        println(sender?.state == NSOnState)
    }
    
}
