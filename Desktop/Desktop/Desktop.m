#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "Desktop.h"

void SDegutisObserverCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    void(^thing)(AXUIElementRef) = (__bridge void (^)(AXUIElementRef))(refcon);
    thing(element);
}

AXObserverCallback SDegutisObserverCallbackTrampoline(void) {
    return &SDegutisObserverCallback;
}
