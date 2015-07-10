import Cocoa
import XCTest
import Lua

class Lua_Tests: XCTestCase {
    
    func testFundamentals() {
        let vm = Lua.VirtualMachine()
        let table = vm.createTable()
        table[3] = "foo"
        XCTAssert(table[3] is String)
        XCTAssertEqual(table[3] as! String, "foo")
    }
    
    func testStringX() {
        let vm = Lua.VirtualMachine()
        
        let stringxLib = vm.createTable()
        
        stringxLib["split"] = vm.createFunction([String.arg, String.arg]) { args in
            let (subject, separator) = (args.string, args.string)
            let fragments = subject.componentsSeparatedByString(separator)
            
            let results = vm.createTable()
            for (i, fragment) in fragments.enumerate() {
                results[i+1] = fragment
            }
            return .Value(results)
        }
        
        vm.globals["stringx"] = stringxLib
        
        switch vm.eval("return stringx.split('hello world', ' ')", args: []) {
        case let .Values(values):
            XCTAssertEqual(values.count, 1)
            XCTAssert(values[0] is Table)
            let array: [String] = (values[0] as! Table).asSequence()
            XCTAssertEqual(array, ["hello", "world"])
        case let .Error(e):
            XCTFail(e)
        }
    }
    
}
