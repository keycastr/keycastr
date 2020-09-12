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


#import "KCKeystrokeTransformer.h"
#import "KCKeystroke.h"

@interface KCKeystrokeTransformer (Private)

-(NSDictionary*) _specialKeys;

@end


@implementation KCKeystrokeTransformer

static NSString* kCommandKeyString = @"\xe2\x8c\x98";
static NSString* kAltKeyString = @"\xe2\x8c\xa5";
static NSString* kControlKeyString = @"\xe2\x8c\x83";
static NSString* kShiftKeyString = @"\xe2\x87\xa7";
static NSString* kLeftTabString = @"\xe2\x87\xa4";

#define UTF8(x) [NSString stringWithUTF8String:x]
#define NSNum(x) [NSNumber numberWithInt:x]

+(BOOL) allowsReverseTransformation
{
	return NO;
}

+(Class) transformedValueClass
{
	return [NSString class];
}

+(KCKeystrokeTransformer*) sharedTransformer
{
	static KCKeystrokeTransformer* xformer = nil;
	if (xformer == nil)
	{
		xformer = [[KCKeystrokeTransformer alloc] init];
	}
	return xformer;
}

-(NSDictionary*) _specialKeys
{
	static NSDictionary *d = nil;
	if (d == nil)
	{
		d = [[NSDictionary alloc] initWithObjectsAndKeys:
			UTF8("\xe2\x87\xa1"), NSNum(126), // up
			UTF8("\xe2\x87\xa3"), NSNum(125), // down
			UTF8("\xe2\x87\xa2"), NSNum(124), // right
			UTF8("\xe2\x87\xa0"), NSNum(123), // left
			UTF8("\xe2\x87\xa5"), NSNum(48), // tab
			UTF8("\xe2\x8e\x8b"), NSNum(53), // escape
			UTF8("\xe2\x8e\x8b"), NSNum(71), // escape
			UTF8("\xe2\x8c\xab"), NSNum(51), // delete
			UTF8("\xe2\x8c\xa6"), NSNum(117), // forward delete
			UTF8("?\xe2\x83\x9d"), NSNum(114), // help
			UTF8("\xe2\x86\x96"), NSNum(115), // home
			UTF8("\xe2\x86\x98"), NSNum(119), // end
			UTF8("\xe2\x87\x9e"), NSNum(116), // pgup
			UTF8("\xe2\x87\x9f"), NSNum(121), // pgdn
			UTF8("\xe2\x86\xa9"), NSNum(36), // return
			UTF8("\xe2\x86\xa9"), NSNum(76), // numpad enter
			UTF8("F1"), NSNum(122), // F1
			UTF8("F2"), NSNum(120), // F2
			UTF8("F3"), NSNum(99),  // F3
			UTF8("F4"), NSNum(118), // F4
			UTF8("F5"), NSNum(96),  // F5
			UTF8("F6"), NSNum(97),  // F6
			UTF8("F7"), NSNum(98),  // F7
			UTF8("F8"), NSNum(100), // F8
			UTF8("F9"), NSNum(101), // F9
			UTF8("F10"), NSNum(109), // F10
			UTF8("F11"), NSNum(103), // F11
			UTF8("F12"), NSNum(111), // F12
			UTF8("F13"), NSNum(105), // F13
			UTF8("F14"), NSNum(107), // F14
			UTF8("F15"), NSNum(113), // F15
			UTF8("F16"), NSNum(106), // F16
			UTF8("F17"), NSNum(64), // F17
			UTF8("F18"), NSNum(79), // F18
			UTF8("F19"), NSNum(80), // F19
			UTF8("F20"), NSNum(90), // F20
			UTF8("\xe2\x90\xa3\xe2\x80\x8b"), NSNum(49), // space
			nil];
	}
	return d;
}

-(id) transformedValue:(id)value
{
	KCKeystroke* keystroke = (KCKeystroke*)value;
	NSMutableString* mutableResponse = [NSMutableString string];

	NSEventModifierFlags _modifiers = [keystroke modifiers];
	uint16_t _keyCode = [keystroke keyCode];

	BOOL isShifted = NO;
	BOOL needsShiftGlyph = NO;
	BOOL isCommand = NO;

	if (_modifiers & NSControlKeyMask)
	{
		isCommand = YES;
		[mutableResponse appendString:kControlKeyString];
	}

	if (_modifiers & NSAlternateKeyMask)
	{
		isCommand = YES;
		[mutableResponse appendString:kAltKeyString];
	}

	if (_modifiers & NSShiftKeyMask)
	{
		isShifted = YES;
		if (isCommand)
			[mutableResponse appendString:kShiftKeyString];
		else
			needsShiftGlyph = YES;
	}

	if (_modifiers & NSCommandKeyMask)
	{
		if (needsShiftGlyph)
		{
			[mutableResponse appendString:kShiftKeyString];
			needsShiftGlyph = NO;
		}
		isCommand = YES;
		[mutableResponse appendString:kCommandKeyString];
	}

	if (isShifted && !isCommand)
    {
        if ([@(_keyCode) isEqualToNumber:@48]) {
            [mutableResponse appendString:kLeftTabString];
            return mutableResponse;
        }
    }

	NSString *specialKeyString = [[self _specialKeys] objectForKey:@(_keyCode)];
	if (specialKeyString)
	{
        if (needsShiftGlyph) {
			[mutableResponse appendString:kShiftKeyString];
        }
		[mutableResponse appendString:specialKeyString];

        return mutableResponse;
	}

    //TODO: maybe this doesn't make sense as we're checking -characters and then returning -charactersIgnoringModifiers
    if (keystroke.isLetter) {
        [mutableResponse appendString:keystroke.charactersIgnoringModifiers];
    }
    else {
        [mutableResponse appendString:[self preferredCharactersForKeystroke:keystroke]];
    }

    // If this is a command string, put it in uppercase.
    if (isCommand)
	{
        mutableResponse = [[[mutableResponse uppercaseString] mutableCopy] autorelease];
	}
	
	return mutableResponse;
}

- (NSString *)preferredCharactersForKeystroke:(KCKeystroke *)keystroke {
    static NSCharacterSet *alphanumericSet = nil;
    if (alphanumericSet == nil) {
        alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
    }

	if ((keystroke.characters.length > 0) && [alphanumericSet characterIsMember:[keystroke.characters characterAtIndex:0]]) {
		return keystroke.characters;
	} else {
		return keystroke.charactersIgnoringModifiers;
	}
}

@end
