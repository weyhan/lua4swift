#import <Foundation/Foundation.h>
#import "lua.h"

lua_CFunction SDegutisLuaTrampoline(int(^fn)(lua_State*));
