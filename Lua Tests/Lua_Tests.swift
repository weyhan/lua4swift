import Cocoa
import XCTest
import Lua

class Lua_Tests: XCTestCase {
    
    func testFundamentals() {
        let vm = Lua.VirtualMachine()
        let table = vm.createTable()
        table[3] = "foo"
        XCTAssert(table[3] is String)
        XCTAssertEqual(table[3] as String, "foo")
    }
    
}
