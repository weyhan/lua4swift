#ifndef DIY_Window_Manager_Something_h
#define DIY_Window_Manager_Something_h

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

void SDegutisSetupHotkeyCallback(BOOL(^thing)(UInt32 i, BOOL down));
CF_RETURNS_NOT_RETAINED EventHotKeyRef SDegutisRegisterHotkey(UInt32 uid, UInt32 keycode, BOOL cmd, BOOL ctrl, BOOL shift, BOOL alt);

#endif
