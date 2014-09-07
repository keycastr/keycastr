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


#include <Carbon/Carbon.h>
#import "KCKeyboardTap.h"
#import "KCUtility.h"

@interface KCKeyboardTap (Private)

-(void) _noteKeyEvent:(CGEventRef)event;
-(void) _noteFlagsChanged:(CGEventRef)event;

@end

/*
static int
GetKeyboardLayout( Ptr* resource )
{
    static Boolean initialized = false;
    static SInt16 lastKeyLayoutID = -1;
    static Handle uchrHnd = NULL;
    static Handle KCHRHnd = NULL;

    SInt16 keyScript;
    SInt16 keyLayoutID;

    keyScript = GetScriptManagerVariable(smKeyScript);
    keyLayoutID = GetScriptVariable(keyScript,smScriptKeys);

    if (!initialized || (lastKeyLayoutID != keyLayoutID)) {
        initialized = true;
        // deadKeyStateUp = deadKeyStateDown = 0;
        lastKeyLayoutID = keyLayoutID;
        uchrHnd = GetResource('uchr',keyLayoutID);
        if (NULL == uchrHnd) {
            KCHRHnd = GetResource('KCHR',keyLayoutID);
        }
        if ((NULL == uchrHnd) && (NULL == KCHRHnd)) {
            initialized = false;
            fprintf (stderr,
                    "GetKeyboardLayout(): "
                    "Can't get a keyboard layout for layout %d "
                    "(error code %d)?\n",
                    (int) keyLayoutID, (int) ResError());
            *resource = (Ptr)GetScriptManagerVariable(smKCHRCache);
            fprintf (stderr,
                    "GetKeyboardLayout(): Trying the cache: %p\n",
                    *resource);
            return 0;
        }
    }

    if (NULL != uchrHnd) {
        *resource = *uchrHnd;
        return 1;
    } else {
        *resource = *KCHRHnd;
        return 0;
    }
}
*/

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
	}
	return NULL;
}

@implementation KCKeyboardTap

-(id) init
{
	if (!(self = [super init]))
		return nil;

	static BOOL tapInstalled = NO;
	if (!tapInstalled)
	{
		// We have to try to tap the keydown event independently because CGEventTapCreate will succeed if it can
		// install the event tap for the flags changed event, which apparently doesn't require universal access
		// to be enabled.  Thus, the call would succeed but KeyCastr would be, um, useless.
		CFMachPortRef tap = CGEventTapCreate(
			kCGSessionEventTap,
			kCGHeadInsertEventTap,
			kCGEventTapOptionListenOnly,
			CGEventMaskBit(kCGEventKeyDown),
			eventTapCallback,
			self
			);
        if (tap != NULL) {
            CFRelease( tap );
        } else {
            FAIL_LOUDLY( YES , @"Could not create event tap.  Make sure 'Enable Access for Assistive Devices' is checked in the Universal Access preferences." );
        }

		tap = CGEventTapCreate(
			kCGSessionEventTap,
			kCGHeadInsertEventTap,
			kCGEventTapOptionListenOnly,
			CGEventMaskBit(kCGEventKeyDown) | CGEventMaskBit(kCGEventFlagsChanged),
			eventTapCallback,
			self
			);
		FAIL_LOUDLY( tap == NULL, @"Could not create event tap.  Make sure 'Enable Access for Assistive Devices' is checked in the Universal Access preferences." );

//		GetKeyboardLayout( &_kybdLayout );

		CFRunLoopSourceRef eventSrc = CFMachPortCreateRunLoopSource(NULL, tap, 0);
		FAIL_LOUDLY( eventSrc == NULL, @"Could not create a run loop source." );

		CFRunLoopRef runLoop = CFRunLoopGetCurrent();
		FAIL_LOUDLY( runLoop == NULL, @"There is no current run loop." );

		CFRunLoopAddSource( runLoop, eventSrc, kCFRunLoopDefaultMode );
		if ( eventSrc != NULL) {
			CFRelease( eventSrc );
		}
		if (tap != NULL) {
			CFRelease( tap );
		}
	}

	return self;
}

- (void)dealloc {
    [_delegate release];
    [super dealloc];
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

-(void) _noteKeyEvent:(CGEventRef)event
{
	uint32_t modifiers = 0;
	CGEventFlags f = CGEventGetFlags( event );
	CGKeyCode keyCode = CGEventGetIntegerValueField( event, kCGKeyboardEventKeycode );
	CGKeyCode charCode = keyCode;

	if (f & kCGEventFlagMaskShift)
		modifiers |= NSShiftKeyMask;
	
	if (f & kCGEventFlagMaskCommand)
		modifiers |= NSCommandKeyMask;

	if (f & kCGEventFlagMaskControl)
		modifiers |= NSControlKeyMask;
	
	if (f & kCGEventFlagMaskAlternate)
		modifiers |= NSAlternateKeyMask;
	
	
/*
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	id obj = [defaults objectForKey:@"ShortcutRecorder toggleCapture"];
	if (obj != nil)
	{
		CGKeyCode toggleKeyCode = [[obj valueForKey:@"keyCode"] longValue];
		CGEventFlags toggleFlags = [[obj valueForKey:@"modifierFlags"] longValue] & NSDeviceIndependentModifierFlagsMask;
		if (toggleKeyCode == charCode && toggleFlags == (f & NSDeviceIndependentModifierFlagsMask))
		{
			capturing = !capturing;
			[visualizer setCapturing:capturing];
			return; // we don't echo the capturing command
		}
	}

	if (capturing == NO)
		return;
*/
	
	UniChar buf[3] = {0};
	UInt32 len;
	UInt32 deadKeys = 0;

	KeyboardLayoutRef keyboardLayout;
	if (KLGetCurrentKeyboardLayout(&keyboardLayout) != noErr)
	{
		FAIL_LOUDLY( 1, @"Could not get current keyboard layout." );
	}

	KeyboardLayoutKind keyboardKind;
	if (KLGetKeyboardLayoutProperty(keyboardLayout, kKLKind, (const void**)&keyboardKind) != noErr)
	{
		FAIL_LOUDLY( 1, @"Could not get keyboard kind." );
	}

	if (keyboardKind == kKLKCHRKind)
	{
		Handle kchrHandle;
		if (KLGetKeyboardLayoutProperty(keyboardLayout, kKLKCHRData, (const void**)&kchrHandle) != noErr)
		{
			FAIL_LOUDLY( 1, @"Could not get keyboard KCHR data." );
		}
		UInt32 modifiers = 0;
		if (f & kCGEventFlagMaskShift && !(f & (kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate | kCGEventFlagMaskControl)))
			modifiers |= shiftKey;
		if (f & kCGEventFlagMaskAlphaShift)
			modifiers |= alphaLock;

		UInt16 keyCode = (charCode & 0x3f) | modifiers;
		UInt32 state = 0;

		char c = 0xff & KeyTranslate( kchrHandle, keyCode, &state );
		if (state != 0)
			c = 0xff & KeyTranslate( kchrHandle, keyCode, &state );
		buf[0] = [[[[NSString alloc] initWithData:[NSData dataWithBytes:&c length:1] encoding:NSMacOSRomanStringEncoding] autorelease] characterAtIndex:0];

		charCode = buf[0];
	}
	else if (keyboardKind == kKLKCHRuchrKind || keyboardKind == kKLuchrKind)
	{
		const void* resource;
		if (KLGetKeyboardLayoutProperty(keyboardLayout, kKLuchrData, &resource) != noErr)
		{
			FAIL_LOUDLY( 1, @"Could not get keyboard UCHR data." );
		}
			
		UInt32 modifiers = 0;
		if (f & kCGEventFlagMaskShift && !(f & (kCGEventFlagMaskCommand | kCGEventFlagMaskAlternate | kCGEventFlagMaskControl)))
			modifiers |= shiftKey;
		if (f & kCGEventFlagMaskAlphaShift)
			modifiers |= alphaLock;

		if (UCKeyTranslate (
			resource,
			charCode,
			kUCKeyActionDown,
			(modifiers >> 8) & 0xff,
			CGEventGetIntegerValueField( event, kCGKeyboardEventKeyboardType ),
			kUCKeyTranslateNoDeadKeysMask,
			&deadKeys,
			2,
			&len,
			buf
			) != noErr)
		{
			FAIL_LOUDLY( 1, @"Could not translate keystroke into characters via UCHR data." );
		}
		
		charCode = buf[0];
	}
	else
	{
		FAIL_LOUDLY( 1, @"Keyboard is neither KCHR or UCHR." );
	}

	KCKeystroke* e = [[[KCKeystroke alloc] initWithKeyCode:keyCode characterCode:charCode modifiers:modifiers] autorelease];
	[self noteKeyEvent:e];
}

-(void) noteKeyEvent:(KCKeystroke*)keystroke
{
	if ([_delegate respondsToSelector:@selector(keyboardTap:noteKeystroke:)])
		[_delegate keyboardTap:self noteKeystroke:keystroke];
}

-(void) noteFlagsChanged:(uint32_t)newFlags
{
	if ([_delegate respondsToSelector:@selector(keyboardTap:noteFlagsChanged:)])
		[_delegate keyboardTap:self noteFlagsChanged:newFlags];
}

-(void) addObserver:(id)recipient selector:(SEL)aSelector
{
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center addObserver:recipient selector:aSelector name:@"KCKeystrokeEvent" object:self];
}

-(void) removeObserver:(id)recipient
{
	NSNotificationCenter* center = [NSNotificationCenter defaultCenter];
	[center removeObserver:recipient];
}

+(KCKeyboardTap*) sharedKeyboardTap
{
	static KCKeyboardTap* sharedTap = nil;
	if (sharedTap == nil)
	{
		sharedTap = [[KCKeyboardTap alloc] init];
	}
	return sharedTap;
}

-(id) delegate
{
	return _delegate;
}

-(void) setDelegate:(id)delegate
{
	if (delegate == _delegate)
		return;
	[_delegate release];
	_delegate = [delegate retain];
}

@end