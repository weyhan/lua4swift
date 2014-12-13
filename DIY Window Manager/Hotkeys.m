#import "Hotkeys.h"

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

EventHotKeyRef SDegutisRegisterHotkey(UInt32 uid, UInt32 keycode, BOOL cmd, BOOL ctrl, BOOL shift, BOOL alt) {
    EventHotKeyID hotKeyID = {.signature = 1234, .id = uid};
    
    UInt32 mods = 0;
    if (ctrl)  mods |= controlKey;
    if (cmd)   mods |= cmdKey;
    if (shift) mods |= shiftKey;
    if (alt)   mods |= optionKey;
    
    EventHotKeyRef carbonHotKey;
    RegisterEventHotKey(keycode,
                        mods,
                        hotKeyID,
                        GetEventDispatcherTarget(),
                        kEventHotKeyExclusive,
                        &carbonHotKey);
    
    return carbonHotKey;
}
