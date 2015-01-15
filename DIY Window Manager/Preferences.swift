import Cocoa

public class BindableVariable<T> {
    
    typealias Callback = (T) -> ()
    
    public var value: T {
        willSet { for fn in observers { fn(value) } }
    }
    
    public init(_ initial: T) {
        value = initial
    }
    
    var observers = [Callback]()
    
    public func addObserver(fn: Callback) -> Callback {
        observers.append(fn)
        return fn
    }
    
}

class FakeAutoLoginManager {
    
    private var autoLogin = BindableVariable(false)
    let fn: Any
    
    init() {
        fn = autoLogin.addObserver() { enabled in
            println("setting autologin! \(enabled)")
        }
    }
    
}

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var checkbox: NSButton!
    let alm = FakeAutoLoginManager()
    
    override convenience init() {
        self.init(windowNibName: "Preferences")
    }
    
    override func windowDidLoad() {
        println("wloaded")
        
        checkbox.state = alm.autoLogin.value ? NSOnState : NSOffState
        checkbox.target = self
        checkbox.action = "clickedButton:"
    }
    
    func clickedButton(sender: NSButton!) {
        if sender == nil { return }
        alm.autoLogin.value = (checkbox.state == NSOnState)
    }
    
}
