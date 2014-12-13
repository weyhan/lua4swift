//
//  Wrappers.swift
//  DIY Window Manager
//
//  Created by Steven Degutis on 11/25/14.
//  Copyright (c) 2014 Tiny Robot Software. All rights reserved.
//

import Foundation
import JavaScriptCore

@objc
protocol FooProtocol: JSExport {
    var thing: Int { get set}
    
    func bla() -> Int
}

@objc
class Foo: NSObject, FooProtocol {
    var thing = 2
    
    func bla() -> Int {
        return thing + 3
    }
}

func testWrappers() {
    var vm = JSVirtualMachine()
    var ctx = JSContext(virtualMachine: vm)
    ctx.exceptionHandler = { ctx, val in
        println("js error: \(val)")
    }
    ctx.setObject(Foo(), forKeyedSubscript: "k")
    ctx.evaluateScript("k.thing = 9")
    println(ctx.evaluateScript("k.bla()"))
}
