//
//  Graphite.h
//  Graphite
//
//  Created by Steven Degutis on 12/21/14.
//  Copyright (c) 2014 Tiny Robot Software. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

void SDegutisSetupHotkeyCallback(BOOL(^thing)(UInt32 i, BOOL down));
void* SDegutisRegisterHotkey(UInt32 uid, UInt32 keycode, UInt32 mods);
void SDegutisUnregisterHotkey(void* hotkey);
