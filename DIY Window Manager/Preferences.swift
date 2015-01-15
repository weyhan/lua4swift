import Cocoa

protocol BooleanBindableStorage {
    func set(Bool)
    func get() -> Bool
}

protocol BooleanBindableControl {
    func set(Bool)
    func get() -> Bool
    weak var target: AnyObject? { get set }
    var action: Selector { get set }
}

class FakeAutoLoginManager: BooleanBindableStorage {
    private var _autoLogin: Bool = false
    
    func get() -> Bool {
        println("getting autologin!")
        return _autoLogin
    }
    
    func set(enabled: Bool) {
        println("setting autologin! \(enabled)")
        _autoLogin = enabled
    }
}

extension NSButton: BooleanBindableControl {
    func set(value: Bool) { self.state = value ? NSOnState : NSOffState }
    func get() -> Bool    { return self.state == NSOnState }
}

enum Binder {
    
    case CheckboxValue(BooleanBindableStorage, BooleanBindableControl)
    
    func trampoline() -> NSObject {
        switch self {
        case let .CheckboxValue(storage, control):
            return CheckboxBinding
        }
    }
    
}

class CheckboxBinding: NSObject {
    
    let b: BooleanBindableStorage
    let initialValue: Bool
    
    init(_ b: BooleanBindableStorage) {
        println("in here")
        self.b = b
        initialValue = b.get()
    }
    
    func bind(var button: BooleanBindableControl) {
        println("binding: \(button)")
        button.set(initialValue)
        button.target = self
        button.action = "clickedButton:"
    }
    
    func clickedButton(sender: NSButton!) {
        if sender == nil { return }
        b.set(sender.get())
    }
    
    deinit {
        println("bye")
    }
    
}

class PreferencesController: NSWindowController {
    
    @IBOutlet weak var checkbox: NSButton!
    let checkboxBinding = CheckboxBinding(FakeAutoLoginManager())
    
    override convenience init() {
        self.init(windowNibName: "Preferences")
    }
    
    override func windowDidLoad() {
        println("wloaded")
        checkboxBinding.bind(checkbox)
    }
    
}
