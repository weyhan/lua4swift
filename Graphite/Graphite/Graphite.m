//
//  Graphite.m
//  Graphite
//
//  Created by Steven Degutis on 12/21/14.
//  Copyright (c) 2014 Tiny Robot Software. All rights reserved.
//

#import "Graphite.h"

static OSStatus hotkey_callback(EventHandlerCallRef inHandlerCallRef, EventRef inEvent, void *inUserData) {
    EventHotKeyID eventID;
    GetEventParameter(inEvent, kEventParamDirectObject, typeEventHotKeyID, NULL, sizeof(eventID), NULL, &eventID);
    
    BOOL(^thing)(UInt32 i, BOOL down) = (__bridge id)inUserData;
    thing(eventID.id, GetEventKind(inEvent) == kEventHotKeyPressed);
    
    return noErr;
}

void SDegutisSetupHotkeyCallback(BOOL(^thing)(UInt32 i, BOOL down)) {
    EventTypeSpec hotKeyPressedSpec[] = {
        {kEventClassKeyboard, kEventHotKeyPressed},
        {kEventClassKeyboard, kEventHotKeyReleased},
    };
    
    InstallEventHandler(GetEventDispatcherTarget(),
                        hotkey_callback,
                        sizeof(hotKeyPressedSpec) / sizeof(EventTypeSpec),
                        hotKeyPressedSpec,
                        (__bridge_retained void*)[thing copy],
                        NULL);
}

void* SDegutisRegisterHotkey(UInt32 uid, UInt32 keycode, UInt32 mods) {
    EventHotKeyID hotKeyID = {.signature = 'DYWM', .id = uid};
    
    EventHotKeyRef carbonHotKey;
    RegisterEventHotKey(keycode,
                        mods,
                        hotKeyID,
                        GetEventDispatcherTarget(),
                        kEventHotKeyExclusive,
                        &carbonHotKey);
    
    return carbonHotKey;
}

void SDegutisUnregisterHotkey(void* hotkey) {
    UnregisterEventHotKey(hotkey);
}
