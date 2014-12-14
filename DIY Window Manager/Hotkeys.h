#ifndef DIY_Window_Manager_Something_h
#define DIY_Window_Manager_Something_h

#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>

void SDegutisSetupHotkeyCallback(BOOL(^thing)(UInt32 i, BOOL down));
void* SDegutisRegisterHotkey(UInt32 uid, UInt32 keycode, UInt32 mods);
void SDegutisUnregisterHotkey(void* hotkey);

#endif
