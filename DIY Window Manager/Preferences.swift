import Cocoa

class ActionTrampoline: NSObject {
    
    let fn: (Bool) -> Void
    init(_ fn: (Bool) -> Void) { self.fn = fn }
    
    func clickedButton(sender: NSButton?) {
        fn(sender?.state == NSOnState)
    }
    
    deinit {
        println("bye")
    }
    
}

extension NSButton {
    
    func shimmy(fn: (Bool) -> Void) -> ActionTrampoline {
        let t = ActionTrampoline(fn)
        self.target = t
        self.action = "clickedButton:"
        return t
    }
    
}

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var checkbox: NSButton!
    var checkboxTrampoline: ActionTrampoline?
    
    override var windowNibName: String? { return "Preferences" }
    
    override func windowDidLoad() {
        checkboxTrampoline = self.checkbox.shimmy({ welp in
            println(("welp", welp))
        })
    }
    
    @IBAction func clickCheckbox(sender: NSButton?) {
        println(sender?.state == NSOnState)
    }
    
}
