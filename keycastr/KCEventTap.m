//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2014-2024 Andrew Kitchen
//
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//	*	Redistributions of source code must retain the above copyright notice, this
//		list of conditions and the following disclaimer.
//	*	Redistributions in binary form must reproduce the above copyright notice,
//		this list of conditions and the following disclaimer in the documentation
//		and/or other materials provided with the distribution.
//	*	Neither the name KeyCastr nor the names of its contributors may be used to
//		endorse or promote products derived from this software without specific
//		prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if !__has_feature(objc_arc)
#error "ARC is required for this file -- enable with -fobjc-arc"
#endif

#import "KCEventTap.h"
#import "KCKeystroke.h"
#import "KCKeycastrEvent.h"
#import "KCMouseEvent.h"

@interface KCEventTap () {
    CFMachPortRef keyEventTap;
    CFMachPortRef mouseAndFlagsEventTap;
    CFRunLoopSourceRef keyEventTapSource;
    CFRunLoopSourceRef mouseAndFlagsEventTapSource;
}

- (void)_noteMouseEvent:(CGEventRef)eventRef;
- (void)_noteKeyEvent:(CGEventRef)eventRef;
- (void)_noteFlagsChanged:(CGEventRef)event;

@end

CGEventRef keyEventTapCallback(
   CGEventTapProxy proxy,
   CGEventType type,
   CGEventRef event,
   void *context)
{
    KCEventTap *eventTap = (__bridge KCEventTap *)context;
    switch (type)
    {
        case kCGEventKeyDown:
            [eventTap _noteKeyEvent:event];
            break;
        case kCGEventKeyUp:
            break;
        default:
            break;
    }
    return event;
}

CGEventRef mouseAndFlagsEventTapCallback(
   CGEventTapProxy proxy,
   CGEventType type,
   CGEventRef event,
   void *context)
{
    KCEventTap *eventTap = (__bridge KCEventTap *)context;
    switch (type)
    {
        case kCGEventLeftMouseDown:
        case kCGEventRightMouseDown:
        case kCGEventLeftMouseUp:
        case kCGEventRightMouseUp:
        case kCGEventLeftMouseDragged:
        case kCGEventRightMouseDragged:
        case kCGEventOtherMouseDown:
        case kCGEventOtherMouseUp:
        case kCGEventOtherMouseDragged:
            [eventTap _noteMouseEvent:event];
            break;
        case kCGEventFlagsChanged:
            [eventTap _noteFlagsChanged:event];
            break;
        default:
            break;
    }
    return event;
}

@implementation KCEventTap

-(id) init
{
	if (!(self = [super init]))
		return nil;

	return self;
}

- (void)dealloc {
    if (_tapInstalled) {
        [self removeTap];
    }
}

-(NSError*) constructErrorWithDescription:(NSString*)description {
    return [NSError errorWithDomain:NSBundle.mainBundle.bundleIdentifier
                               code:0
                           userInfo:@{
                                      NSLocalizedDescriptionKey: NSLocalizedString(description, nil)
                                      }];
}

-(BOOL) installTapWithError:(NSError **)error {
    if (_tapInstalled) {
        return YES;
    }
    
    // We have to try to tap the keydown event independently because CGEventTapCreate will succeed if it can
    // install the event tap for the flags changed event, which apparently doesn't require universal access
    // to be enabled.  Thus, the call would succeed but KeyCastr would be, um, useless.
    keyEventTap = CGEventTapCreate(kCGSessionEventTap,
                                   kCGHeadInsertEventTap,
                                   kCGEventTapOptionListenOnly,
                                   CGEventMaskBit(kCGEventKeyDown)
                                   | CGEventMaskBit(kCGEventKeyUp),
                                   keyEventTapCallback,
                                   (__bridge void *)self
                                   );

    if (keyEventTap == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create key event tap! Permissions needed..."];
        }
        return NO;
    }
    
    mouseAndFlagsEventTap = CGEventTapCreate(kCGSessionEventTap,
                                                    kCGHeadInsertEventTap,
                                                    kCGEventTapOptionListenOnly,
                                                    CGEventMaskBit(kCGEventLeftMouseDown)
                                                    | CGEventMaskBit(kCGEventLeftMouseUp)
                                                    | CGEventMaskBit(kCGEventRightMouseDown)
                                                    | CGEventMaskBit(kCGEventRightMouseUp)
                                                    | CGEventMaskBit(kCGEventLeftMouseDragged)
                                                    | CGEventMaskBit(kCGEventRightMouseDragged)
                                                    | CGEventMaskBit(kCGEventFlagsChanged)
                                                    | CGEventMaskBit(kCGEventOtherMouseDown)
                                                    | CGEventMaskBit(kCGEventOtherMouseUp)
                                                    | CGEventMaskBit(kCGEventOtherMouseDragged),
                                                    mouseAndFlagsEventTapCallback,
                                                    (__bridge void *)self
                                                    );
    
    if (mouseAndFlagsEventTap == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create mouse and modifiers event tap!"];
        }
        return NO;
    }
    
    keyEventTapSource = CFMachPortCreateRunLoopSource(NULL, keyEventTap, 0);
    mouseAndFlagsEventTapSource = CFMachPortCreateRunLoopSource(NULL, mouseAndFlagsEventTap, 0);

    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFRunLoopAddSource(runLoop, keyEventTapSource, kCFRunLoopDefaultMode);
    CFRunLoopAddSource(runLoop, mouseAndFlagsEventTapSource, kCFRunLoopDefaultMode);

    _tapInstalled = YES;
    
    return YES;
}

-(void) removeTap {
    if (!_tapInstalled) {
        return;
    }

    CFRunLoopSourceInvalidate(keyEventTapSource);
    CFRunLoopSourceInvalidate(mouseAndFlagsEventTapSource);

    CFRelease(keyEventTapSource);
    CFRelease(mouseAndFlagsEventTapSource);

    CFRelease(keyEventTap);
    CFRelease(mouseAndFlagsEventTap);

    _tapInstalled = NO;
}

-(void) _noteFlagsChanged:(CGEventRef)event
{
	NSEventModifierFlags modifiers = 0;
	CGEventFlags f = CGEventGetFlags( event );

	if (f & kCGEventFlagMaskShift)
        modifiers |= NSEventModifierFlagShift;
	
	if (f & kCGEventFlagMaskCommand)
        modifiers |= NSEventModifierFlagCommand;

	if (f & kCGEventFlagMaskControl)
        modifiers |= NSEventModifierFlagControl;
	
	if (f & kCGEventFlagMaskAlternate)
        modifiers |= NSEventModifierFlagOption;

	[self noteFlagsChanged:modifiers];
}

-(void) _noteKeyEvent:(CGEventRef)eventRef
{
    NSEvent *event = [NSEvent eventWithCGEvent:eventRef];
    KCKeystroke* keystroke = [KCKeystroke eventWithNSEvent:event];
    [self noteKeystroke:keystroke];
}

- (void)_noteMouseEvent:(CGEventRef)eventRef
{
    NSEvent *event = [NSEvent eventWithCGEvent:eventRef];
    KCMouseEvent *mouseEvent = [KCMouseEvent eventWithNSEvent:event];
    [_delegate eventTap:self noteMouseEvent:mouseEvent];
}

-(void) noteKeystroke:(KCKeystroke*)keystroke
{
    [_delegate eventTap:self noteKeystroke:keystroke];
}

-(void) noteFlagsChanged:(NSEventModifierFlags)newFlags
{
    [_delegate eventTap:self noteFlagsChanged:newFlags];
}

@end
