import Foundation
import AppKit

class Hotkey {
    
    class func setup() {
        
        SDegutisSetupHotkeyCallback { i, down in
            println("swift callback!!! \(i) \(down)")
            return false
        }
        
        SDegutisRegisterHotkey(1, 12, true, false, false, false)
        
    }
    
}
