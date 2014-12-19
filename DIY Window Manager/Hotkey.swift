import Foundation
import AppKit

private var keyToCode = [String:Int]()
private var codeToKey = [Int:String]()

private let relocatableKeyCodes = [
    kVK_ANSI_A, kVK_ANSI_B, kVK_ANSI_C, kVK_ANSI_D, kVK_ANSI_E, kVK_ANSI_F,
    kVK_ANSI_G, kVK_ANSI_H, kVK_ANSI_I, kVK_ANSI_J, kVK_ANSI_K, kVK_ANSI_L,
    kVK_ANSI_M, kVK_ANSI_N, kVK_ANSI_O, kVK_ANSI_P, kVK_ANSI_Q, kVK_ANSI_R,
    kVK_ANSI_S, kVK_ANSI_T, kVK_ANSI_U, kVK_ANSI_V, kVK_ANSI_W, kVK_ANSI_X,
    kVK_ANSI_Y, kVK_ANSI_Z, kVK_ANSI_0, kVK_ANSI_1, kVK_ANSI_2, kVK_ANSI_3,
    kVK_ANSI_4, kVK_ANSI_5, kVK_ANSI_6, kVK_ANSI_7, kVK_ANSI_8, kVK_ANSI_9,
    kVK_ANSI_Grave, kVK_ANSI_Equal, kVK_ANSI_Minus, kVK_ANSI_RightBracket,
    kVK_ANSI_LeftBracket, kVK_ANSI_Quote, kVK_ANSI_Semicolon, kVK_ANSI_Backslash,
    kVK_ANSI_Comma, kVK_ANSI_Slash, kVK_ANSI_Period,
]

private func pushCode(code: Int, key: String) {
    keyToCode[key] = code
    codeToKey[code] = key
}

private let lazilySetupKeycodes: () = Keycode.setup()

struct Keycode {
    
    static func setup() {
        NSNotificationCenter.defaultCenter().addObserverForName(NSTextInputContextKeyboardSelectionDidChangeNotification, object: nil, queue: nil) { note in self.cacheMaps() }
        cacheMaps()
    }
    
    static func cacheMaps() {
        keyToCode.removeAll(keepCapacity: true)
        codeToKey.removeAll(keepCapacity: true)
        
        let currentKeyboard = TISCopyCurrentKeyboardInputSource().takeRetainedValue()
        let rawLayoutData = TISGetInputSourceProperty(currentKeyboard, kTISPropertyUnicodeKeyLayoutData)
        
        if rawLayoutData != nil {
            let layoutData = unsafeBitCast(rawLayoutData, CFDataRef.self)
            var keyboardLayout: UnsafePointer<UCKeyboardLayout> = unsafeBitCast(CFDataGetBytePtr(layoutData), UnsafePointer<UCKeyboardLayout>.self)
            
            var keysDown: UInt32 = 0
            var chars: [UniChar] = [0,0,0,0]
            var realLength: UniCharCount = 0
            
            for code in relocatableKeyCodes {
                UCKeyTranslate(
                    keyboardLayout,
                    UInt16(code),
                    UInt16(kUCKeyActionDisplay),
                    0,
                    UInt32(LMGetKbdType()),
                    OptionBits(kUCKeyTranslateNoDeadKeysBit),
                    &keysDown,
                    4,
                    &realLength,
                    &chars)
                
                let name = "\(Character(UnicodeScalar(chars[0])))"
                pushCode(code, name)
            }
        }
        else {
            pushCode(kVK_ANSI_A, "a")
            pushCode(kVK_ANSI_B, "b")
            pushCode(kVK_ANSI_C, "c")
            pushCode(kVK_ANSI_D, "d")
            pushCode(kVK_ANSI_E, "e")
            pushCode(kVK_ANSI_F, "f")
            pushCode(kVK_ANSI_G, "g")
            pushCode(kVK_ANSI_H, "h")
            pushCode(kVK_ANSI_I, "i")
            pushCode(kVK_ANSI_J, "j")
            pushCode(kVK_ANSI_K, "k")
            pushCode(kVK_ANSI_L, "l")
            pushCode(kVK_ANSI_M, "m")
            pushCode(kVK_ANSI_N, "n")
            pushCode(kVK_ANSI_O, "o")
            pushCode(kVK_ANSI_P, "p")
            pushCode(kVK_ANSI_Q, "q")
            pushCode(kVK_ANSI_R, "r")
            pushCode(kVK_ANSI_S, "s")
            pushCode(kVK_ANSI_T, "t")
            pushCode(kVK_ANSI_U, "u")
            pushCode(kVK_ANSI_V, "v")
            pushCode(kVK_ANSI_W, "w")
            pushCode(kVK_ANSI_X, "x")
            pushCode(kVK_ANSI_Y, "y")
            pushCode(kVK_ANSI_Z, "z")
            pushCode(kVK_ANSI_0, "0")
            pushCode(kVK_ANSI_1, "1")
            pushCode(kVK_ANSI_2, "2")
            pushCode(kVK_ANSI_3, "3")
            pushCode(kVK_ANSI_4, "4")
            pushCode(kVK_ANSI_5, "5")
            pushCode(kVK_ANSI_6, "6")
            pushCode(kVK_ANSI_7, "7")
            pushCode(kVK_ANSI_8, "8")
            pushCode(kVK_ANSI_9, "9")
            pushCode(kVK_ANSI_Grave, "`")
            pushCode(kVK_ANSI_Equal, "=")
            pushCode(kVK_ANSI_Minus, "-")
            pushCode(kVK_ANSI_RightBracket, "]")
            pushCode(kVK_ANSI_LeftBracket, "[")
            pushCode(kVK_ANSI_Quote, "\"")
            pushCode(kVK_ANSI_Semicolon, ";")
            pushCode(kVK_ANSI_Backslash, "\\")
            pushCode(kVK_ANSI_Comma, ",")
            pushCode(kVK_ANSI_Slash, "/")
            pushCode(kVK_ANSI_Period, ".")
        }
        
        pushCode(kVK_F1, "f1")
        pushCode(kVK_F2, "f2")
        pushCode(kVK_F3, "f3")
        pushCode(kVK_F4, "f4")
        pushCode(kVK_F5, "f5")
        pushCode(kVK_F6, "f6")
        pushCode(kVK_F7, "f7")
        pushCode(kVK_F8, "f8")
        pushCode(kVK_F9, "f9")
        pushCode(kVK_F10, "f10")
        pushCode(kVK_F11, "f11")
        pushCode(kVK_F12, "f12")
        pushCode(kVK_F13, "f13")
        pushCode(kVK_F14, "f14")
        pushCode(kVK_F15, "f15")
        pushCode(kVK_F16, "f16")
        pushCode(kVK_F17, "f17")
        pushCode(kVK_F18, "f18")
        pushCode(kVK_F19, "f19")
        pushCode(kVK_F20, "f20")
        
        pushCode(kVK_ANSI_KeypadDecimal, "pad.")
        pushCode(kVK_ANSI_KeypadMultiply, "pad*")
        pushCode(kVK_ANSI_KeypadPlus, "pad+")
        pushCode(kVK_ANSI_KeypadDivide, "pad/")
        pushCode(kVK_ANSI_KeypadMinus, "pad-")
        pushCode(kVK_ANSI_KeypadEquals, "pad=")
        pushCode(kVK_ANSI_Keypad0, "pad0")
        pushCode(kVK_ANSI_Keypad1, "pad1")
        pushCode(kVK_ANSI_Keypad2, "pad2")
        pushCode(kVK_ANSI_Keypad3, "pad3")
        pushCode(kVK_ANSI_Keypad4, "pad4")
        pushCode(kVK_ANSI_Keypad5, "pad5")
        pushCode(kVK_ANSI_Keypad6, "pad6")
        pushCode(kVK_ANSI_Keypad7, "pad7")
        pushCode(kVK_ANSI_Keypad8, "pad8")
        pushCode(kVK_ANSI_Keypad9, "pad9")
        pushCode(kVK_ANSI_KeypadClear, "padclear")
        pushCode(kVK_ANSI_KeypadEnter, "padenter")
        
        pushCode(kVK_Return, "return")
        pushCode(kVK_Tab, "tab")
        pushCode(kVK_Space, "space")
        pushCode(kVK_Delete, "delete")
        pushCode(kVK_Escape, "escape")
        pushCode(kVK_Help, "help")
        pushCode(kVK_Home, "home")
        pushCode(kVK_PageUp, "pageup")
        pushCode(kVK_ForwardDelete, "forwarddelete")
        pushCode(kVK_End, "end")
        pushCode(kVK_PageDown, "pagedown")
        pushCode(kVK_LeftArrow, "left")
        pushCode(kVK_RightArrow, "right")
        pushCode(kVK_DownArrow, "down")
        pushCode(kVK_UpArrow, "up")
    }
    
    static func keyForCode(code: Int) -> String? {
        lazilySetupKeycodes
        return codeToKey[code]
    }
    
    static func codeForKey(key: String) -> Int? {
        lazilySetupKeycodes
        return keyToCode[key]
    }
    
}

private var enabledHotkeys = [UInt32 : Hotkey]()
private let lazilySetupHotkeys: Void = SDegutisSetupHotkeyCallback(Hotkey.callback)

class Hotkey {
    
    enum Mod {
        case Command
        case Control
        case Option
        case Shift
        
        init?(_ str: String) {
            switch str.lowercaseString {
            case "command", "cmd": self = Command
            case "control", "ctrl": self = Control
            case "option", "opt", "alt": self = Option
            case "shift": self = Shift // good old shift, only going by one name
            default: return nil
            }
        }
        
        func toCarbonFlag() -> Int {
            switch self {
            case .Command: return cmdKey
            case .Control: return controlKey
            case .Option: return optionKey
            case .Shift: return shiftKey
            }
        }
    }
    
    typealias Callback = () -> ()
    
    let key: String
    let mods: [Mod]
    let downFn: Callback
    let upFn: Callback?
    
    var carbonHotkey: UnsafeMutablePointer<Void>?
    
    convenience init(key: String, mods: [String], downFn: Callback, upFn: Callback? = nil) {
        let mods: [Mod?] = mods.map{Mod($0)}
        self.init(key: key, mods: mods, downFn: downFn, upFn: upFn)
    }
    
    convenience init(key: String, mods: [Mod?], downFn: Callback, upFn: Callback? = nil) {
        let mods = mods.filter{$0 != nil}.map{$0!}
        self.init(key: key, mods: mods, downFn: downFn, upFn: upFn)
    }
    
    init(key: String, mods: [Mod], downFn: Callback, upFn: Callback? = nil) {
        self.key = key
        self.mods = mods
        self.downFn = downFn
        self.upFn = upFn
    }
    
    func enable() -> (Bool, String) {
        lazilySetupHotkeys
        
        if self.carbonHotkey != nil { return (false, "Hotkey already enabled; disable first.") }
        
        let code = Keycode.codeForKey(key)
        if code == nil { return (false, "Hotkey's key is not valid.") }
        
        let id = UInt32(enabledHotkeys.count)
        enabledHotkeys[id] = self
        
        let carbonModFlags = map(self.mods) { $0.toCarbonFlag() }
        self.carbonHotkey = SDegutisRegisterHotkey(id, UInt32(code!), UInt32(reduce(carbonModFlags, 0, |)))
        
        return (true, "")
    }
    
    func disable() {
        if self.carbonHotkey == nil { return }
        SDegutisUnregisterHotkey(self.carbonHotkey!)
        self.carbonHotkey = nil
    }
    
    class func callback(i: UInt32, down: Bool) -> Bool {
        if let hotkey = enabledHotkeys[i] {
            if down {
                hotkey.downFn()
            }
            else if let upFn = hotkey.upFn {
                upFn()
            }
        }
        
        return false
    }
    
}
