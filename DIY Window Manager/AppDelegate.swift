import Cocoa
import Lua
import Desktop


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
//    let prefs = PreferencesController()
    
    func runtest(L: Lua.VirtualMachine) {
        let stringxLib = L.createTable()
        
        stringxLib["split"] = L.createFunction([.String, .String]) { args in
            let (subject, separator) = (args.string, args.string)
            
            let results = L.createTable()
            for (i, fragment) in enumerate(subject.componentsSeparatedByString(separator)) {
                results[i+1] = fragment
            }
            return .Value(results)
        }
        
        L.globalTable["stringx"] = stringxLib
        
    }
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        
        let vm = Lua.VirtualMachine()
        
        vm.globalTable["Window"] = windowLib(vm)
        vm.globalTable["App"] = appLib(vm)
        vm.eval("w = Window.focusedWindow()")
        vm.eval("p = w:topLeft()")
        vm.eval("p.x = p.x + 10")
        vm.eval("w:setTopLeft(p)")
        vm.eval("print(w:belongsToApp(3))")
        vm.eval("w = nil")
        vm.eval("collectgarbage()")
        
        return;
        
        runtest(vm)
        
        
        
        let globals = vm.globalTable
        globals["Hotkey"] = hotkeyLib(vm)
        
//        println(globals["Hotkey"].kind() == .Table)
        
//        return;
        
        let code = vm.createFunction("return stringx.split('hello', 'el')")
        switch code {
        case let .Value(fn):
            
            let result = fn.call([])
            
            switch result {
            case let .Values(vals):
                println("bound hotkey!")
                println(vals)
                
                if let t = vals[0] as? Table {
                    println(t.values())
                }
            default:
                break
            }
            
            println(fn)
        default:
            break
        }
        
        
//        globals["b"] = "a"
//        globals[globals["b"]] = 32
//        let d = globals["a"] as Double
//        println(d + 5) // prints 37
//        
//        globals["q"] = false
//        println(globals["q"])
//        return
//        
//        
//        let p = globals["print"] as Function
//        let values2 = p.call([d])
//        debugPrintln(values2)
        
//        let n = vm.number(3)
//        let s = vm.string("hi")
        
        let fn = vm.createFunction([.String, .Boolean, .Boolean, .Number]) { args in
            let (a, b, c, d) = (args.string, args.boolean, args.boolean, args.number)
            
            println(a)
            println(b)
            println(c)
            println(d)
            
            return .Values([3, "hi"])
        }
        
        let values = fn.call(["sup", false, true, 25])
        switch values {
        case let .Values(vals):
            let a = vals[0] as Number
            let b = vals[1] as String
            println(a.toInteger())
            println(b)
        case let .Error(err):
            println("Error! \(err)")
        }
        
        
//        let f = vm.createFunction("return 3, foo + 2")
//        
//        switch f {
//        case let .Error(err):
//            println("Error! \(err)")
//        case let .Value(f):
//            let values = f.call([])
//            switch values {
//            case let .Values(vals):
//                println(vals)
//            case let .Error(err):
//                println("Error! \(err)")
//            }
//        }
//        
//        let x: String = "foo"
        
        
        
        
        
        
//        L.errorHandler = nil
//        let errh = L.errorHandler
//        L.errorHandler = { err in
//            println("crap!")
//            errh?(err)
//        }
//        
//        println("before", L.stackSize())
//        L.doString("Hotkey.bind(3)")
//        println("now", L.stackSize())
        
//        vm.pushCustomType(Event)
//        vm.setGlobal("Event")
//        
//        vm.doString("e = Event.windowCreated(function(win) end)")
        
        
        
//        vm.pushCustomType(Hotkey)
//        vm.setGlobal("Hotkey")
        
//        prefs.showWindow(nil)
//        return;
        
        
//        L.doString("Hotkey.bind(3)")
//        L.doString("print(34 + 2)")
//        L.doString("print(Hotkey)")
//        L.doString("print(Hotkey.bind)")
//        L.doString("print(Hotkey.__index)")
//        L.doString("print(Hotkey.__index == Hotkey)")
//        L.doString("k = Hotkey.bind('s', {'cmd', 'shift'}, function() print('ha') end)")
//        L.doString("k:disable()")
//        L.doString("k:enable()")
        
//        vm.doString("Hotkey.bind('s', {'cmd', 'shift'}, function() print(3) end):disable()")
        
//        NSApplication.sharedApplication().terminate(nil)
        
//        let hotkey = Hotkey(key: "s", mods: [Hotkey.Mod.Command, Hotkey.Mod.Shift]) { println("woo!") }
//        hotkey.enable()
//        
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(2 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
//            hotkey.disable()
//            println("bla")
//        }
//        
//        return
        
//        let js = JavaScript()
//        
//        js["Window"] = JSWindow.self
//        js["Hotkey"] = JSHotkey.self
//        js["Utils"] = JSUtils.self
//        js.eval("print = Utils.print")
//        
//        println(js.eval("Hotkey"))
//        println(js.eval("Hotkey.bind"))
//        
//        println(js.eval("Hotkey.bind('s', ['cmd', 'shift'], function() { print('foo') })"))
//        println(js.eval("Window.focusedWindow().title()"))
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}
