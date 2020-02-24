//	Copyright (c) 2009 Stephen Deken
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


#import "KCKeyboardTap.h"

@interface KCKeyboardTap (Private)

-(void) _noteKeyEvent:(CGEventRef)eventRef;
-(void) _noteFlagsChanged:(CGEventRef)event;

@end

CGEventRef eventTapCallback(
   CGEventTapProxy proxy, 
   CGEventType type, 
   CGEventRef event, 
   void *vp)
{
    KCKeyboardTap* keyTap = (KCKeyboardTap*)vp;
    switch (type)
    {
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

@implementation KCKeyboardTap

@synthesize delegate = _delegate;

-(id) init
{
	if (!(self = [super init]))
		return nil;

	return self;
}

- (void)dealloc {
    if (tapInstalled) {
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
    if (tapInstalled) {
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
                                         eventTapCallback,
                                         self
                                         );
    
    if (tapKeyDown == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create keyDown event tap!"];
        }
        return NO;
    }
    CFRelease( tapKeyDown );
    
    keyboardTap = CGEventTapCreate(
                           kCGSessionEventTap,
                           kCGHeadInsertEventTap,
                           kCGEventTapOptionListenOnly,
                           CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged),
                           eventTapCallback,
                           self
                           );
    
    if (keyboardTap == NULL) {
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create keyDown|flagsChanged event tap!"];
        }
        return NO;
    }
    
    keyboardTapEventSource = CFMachPortCreateRunLoopSource(NULL, keyboardTap, 0);
    if (keyboardTapEventSource == NULL) {
        CFRelease(keyboardTap);
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not create run loop source!"];
        }
        return NO;
    }
    
    keyboardTapRunLoop = CFRunLoopGetCurrent();
    if (keyboardTapRunLoop == NULL) {
        CFRelease(keyboardTapEventSource);
        CFRelease(keyboardTap);
        if (error != NULL) {
            *error = [self constructErrorWithDescription:@"Could not get current run loop!"];
        }
        return NO;
    }
    
    CFRunLoopAddSource(keyboardTapRunLoop, keyboardTapEventSource, kCFRunLoopDefaultMode);

    tapInstalled = YES;
    
    return YES;
}

-(void) removeTap {
    if (!tapInstalled) {
        return;
    }
    
    CFRunLoopRemoveSource(keyboardTapRunLoop, keyboardTapEventSource, kCFRunLoopDefaultMode);
    CFRelease(keyboardTapRunLoop);
    CFRelease(keyboardTapEventSource);
    CFRelease(keyboardTap);

    tapInstalled = NO;
}

-(void) _noteFlagsChanged:(CGEventRef)event
{
	uint32_t modifiers = 0;
	CGEventFlags f = CGEventGetFlags( event );

	if (f & kCGEventFlagMaskShift)
		modifiers |= NSShiftKeyMask;
	
	if (f & kCGEventFlagMaskCommand)
		modifiers |= NSCommandKeyMask;

	if (f & kCGEventFlagMaskControl)
		modifiers |= NSControlKeyMask;
	
	if (f & kCGEventFlagMaskAlternate)
		modifiers |= NSAlternateKeyMask;

	[self noteFlagsChanged:modifiers];
}

-(void) _noteKeyEvent:(CGEventRef)eventRef
{
    @autoreleasepool {
        NSEvent *event = [NSEvent eventWithCGEvent:eventRef];
        KCKeystroke* keystroke = [[[KCKeystroke alloc] initWithKeyCode:event.keyCode
                                                             modifiers:event.modifierFlags
                                                            characters:event.characters
                                           charactersIgnoringModifiers:event.charactersIgnoringModifiers] autorelease];
        [self noteKeystroke:keystroke];
        NSLog(@"================> %@", keystroke);
    }
}

-(void) noteKeystroke:(KCKeystroke*)keystroke
{
    [_delegate keyboardTap:self noteKeystroke:keystroke];
}

-(void) noteFlagsChanged:(uint32_t)newFlags
{
    [_delegate keyboardTap:self noteFlagsChanged:newFlags];
}

@end
