//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <Cocoa/Cocoa.h>

// private APIs
extern AXError _AXUIElementGetWindow(AXUIElementRef, CGWindowID* out);

// my stuff
AXObserverCallback SDegutisObserverCallbackTrampoline(void);
