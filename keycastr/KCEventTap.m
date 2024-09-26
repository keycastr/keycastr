//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2014-2023 Andrew Kitchen
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


#import "KCEventTap.h"
#import "KCKeystroke.h"
#import "KCKeycastrEvent.h"
#import "KCMouseEvent.h"

@interface KCEventTap () {
    CFMachPortRef eventTap;
    CFRunLoopRef eventTapRunLoop;
    CFRunLoopSourceRef eventTapEventSource;
}

- (void)_noteMouseEvent:(CGEventRef)eventRef;
- (void)_noteKeyEvent:(CGEventRef)eventRef;
- (void)_noteFlagsChanged:(CGEventRef)event;

@end

CGEventRef nullEventTapCallback(
   CGEventTapProxy proxy,
   CGEventType type,
   CGEventRef event,
   void *vp)
{
    return NULL;
}

CGEventRef eventTapCallback(
   CGEventTapProxy proxy,
   CGEventType type,
   CGEventRef event,
   void *vp)
{
    KCEventTap* keyTap = (KCEventTap*)vp;
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
            [keyTap _noteMouseEvent:event];
            break;
        case kCGEventKeyDown:
            [keyTap _noteKeyEvent:event];
            break;
        case kCGEventFlagsChanged:
            [keyTap _noteFlagsChanged:event];
            break;
        default:
            break;
    }
    return NULL;
}

@implementation KCEventTap

@synthesize delegate = _delegate;

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

    [super dealloc];
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
    CFMachPortRef tapKeyDown = CGEventTapCreate(
                                         kCGSessionEventTap,
                                         kCGHeadInsertEventTap,
                                         kCGEventTapOptionListenOnly,
                                         CGEventMaskBit(kCGEventKeyDown),
                                         nullEventTapCallback,
                                         self
                                         );
    
    if (tapKeyDown == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create keyDown event tap!"];
        }
        return NO;
    }
    CFRelease( tapKeyDown );
    
    eventTap = CGEventTapCreate(
                           kCGSessionEventTap,
                           kCGHeadInsertEventTap,
                           kCGEventTapOptionListenOnly,
                           CGEventMaskBit(kCGEventLeftMouseDown)
                                   | CGEventMaskBit(kCGEventLeftMouseUp)
                                   | CGEventMaskBit(kCGEventRightMouseDown)
                                   | CGEventMaskBit(kCGEventRightMouseUp)
                                   | CGEventMaskBit(kCGEventLeftMouseDragged)
                                   | CGEventMaskBit(kCGEventRightMouseDragged)
                                   | CGEventMaskBit(kCGEventKeyDown)
                                   | CGEventMaskBit(kCGEventFlagsChanged)
                                   | CGEventMaskBit(kCGEventOtherMouseDown)
                                   | CGEventMaskBit(kCGEventOtherMouseUp)
                                   | CGEventMaskBit(kCGEventOtherMouseDragged),
                           eventTapCallback,
                           self
                           );
    
    if (eventTap == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create keyDown|flagsChanged event tap!"];
        }
        return NO;
    }
    
    eventTapEventSource = CFMachPortCreateRunLoopSource(NULL, eventTap, 0);
    if (eventTapEventSource == NULL) {
        CFRelease(eventTap);
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create run loop source!"];
        }
        return NO;
    }
    
    eventTapRunLoop = CFRunLoopGetCurrent();
    if (eventTapRunLoop == NULL) {
        CFRelease(eventTapEventSource);
        CFRelease(eventTap);
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not get current run loop!"];
        }
        return NO;
    }
    
    CFRunLoopAddSource(eventTapRunLoop, eventTapEventSource, kCFRunLoopDefaultMode);

    _tapInstalled = YES;
    
    return YES;
}

-(void) removeTap {
    if (!_tapInstalled) {
        return;
    }
    
    CFRunLoopRemoveSource(eventTapRunLoop, eventTapEventSource, kCFRunLoopDefaultMode);
    CFRelease(eventTapEventSource);
    CFRelease(eventTap);

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
	
	if (f & kCGEventFlagMaskSecondaryFn)
		modifiers |= NSEventModifierFlagFunction;

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
