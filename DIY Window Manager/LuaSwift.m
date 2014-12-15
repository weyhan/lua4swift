#import "LuaSwift.h"
#import <objc/runtime.h>
#import "lua.h"

lua_CFunction SDegutisLuaTrampoline(int(^fn)(lua_State*)) {
    return (lua_CFunction)imp_implementationWithBlock(fn);
}
