#import <Foundation/Foundation.h>
#import <Carbon/Carbon.h>
#import "Desktop.h"

void SDegutisObserverCallback(AXObserverRef observer, AXUIElementRef element, CFStringRef notification, void *refcon) {
    void(^block)(AXUIElementRef) = (__bridge void (^)(AXUIElementRef))(refcon);
    block(element);
}

AXObserverCallback SDegutisObserverCallbackTrampoline(void) {
    return &SDegutisObserverCallback;
}

void* SDegutisVoidStarifyBlock(void(^block)(AXUIElementRef)) {
    return (__bridge_retained void*)(block);
}
