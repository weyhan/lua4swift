import Cocoa

private var _autoLogin: Bool = false

class FakeAutoLoginManager {
    class func autoLogin() -> Bool {
        println("getting autologin!")
        return _autoLogin
    }
    
    class func setAutoLogin(enabled: Bool) {
        println("setting autologin! \(enabled)")
        _autoLogin = enabled
    }
}

class ActionBinding: NSObject {
    
    let setter: (Bool) -> Void
    let initialValue: Bool
    
    init(setter: Bool -> Void, getter: Void -> Bool) {
        println("in here")
        self.setter = setter
        initialValue = getter()
    }
    
    func bind(button: NSButton) {
        println("binding: \(button)")
        button.state = initialValue ? NSOnState : NSOffState
        button.target = self
        button.action = "clickedButton:"
    }
    
    func clickedButton(sender: NSButton?) {
        setter(sender?.state == NSOnState)
    }
    
    deinit {
        println("bye")
    }
    
}

class Thing {
    init() {
        println("THING")
    }
}

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var checkbox: NSButton!
    let checkboxBinding = ActionBinding(setter: FakeAutoLoginManager.setAutoLogin, getter: FakeAutoLoginManager.autoLogin)
    let a = Thing()
    
    override var windowNibName: String? { return "Preferences" }
    
    override func windowDidLoad() {
        println("wloaded")
        checkboxBinding.bind(checkbox)
    }
    
}
