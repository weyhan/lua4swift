//
//  SDLuaBridger.m
//  LuaSwift
//
//  Created by Steven Degutis on 12/1/14.
//  Copyright (c) 2014 Tiny Robot Software. All rights reserved.
//

#import "LuaSwift.h"
#import <objc/runtime.h>
#import "lua.h"

lua_CFunction SDLuaTrampoline(int(^fn)(lua_State*)) {
    return (lua_CFunction)imp_implementationWithBlock(fn);
}
