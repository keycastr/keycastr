//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2017-2024 Andrew Kitchen
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

#import "KCEventTransformer.h"
#import "KCKeystroke.h"
#import "KCMouseEvent.h"

static KCEventTransformer *__currentTransformer = nil;

static void _onSelectedKeyboardInputSourceChanged(CFNotificationCenterRef aCenter,
                                                 void *anObserver,
                                                 CFNotificationName aName,
                                                 const void *anObject,
                                                 CFDictionaryRef aUserInfo)
{
    __currentTransformer = nil;
}

@interface KCEventTransformer ()
@property (nonatomic, readonly) TISInputSourceRef keyboardLayout;
@property (nonatomic, assign) BOOL displayModifiedCharacters;
@end

@implementation KCEventTransformer {
    NSUserDefaults *_userDefaults;
	const UCKeyboardLayout *_uchrData;
    BOOL _inputSourceChangeObserved;
}

static NSString* kCommandKeyString = @"\xe2\x8c\x98";
static NSString* kOptionKeyString = @"\xe2\x8c\xa5";
static NSString* kControlKeyString = @"\xe2\x8c\x83";
static NSString* kShiftKeyString = @"\xe2\x87\xa7";
static NSString* kLeftTabString = @"\xe2\x87\xa4";

#define UTF8(x) [NSString stringWithUTF8String:x]

@synthesize keyboardLayout = _keyboardLayout;

+ (BOOL)allowsReverseTransformation
{
	return NO;
}

+ (Class)transformedValueClass
{
	return [NSString class];
}

+ (instancetype)currentTransformer
{
    if (__currentTransformer == nil) {
        TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();
        __currentTransformer = [[KCEventTransformer alloc] initWithKeyboardLayout:currentLayout userDefaults:NSUserDefaults.standardUserDefaults];
        CFRelease(currentLayout);
    }

    return __currentTransformer;
}

- (instancetype)initWithKeyboardLayout:(TISInputSourceRef)keyboardLayout userDefaults:(NSUserDefaults *)userDefaults
{
    if (self = [super init]) {
        CFRetain(keyboardLayout);
        _keyboardLayout = keyboardLayout;
        _userDefaults = userDefaults;

        CFDataRef uchr = TISGetInputSourceProperty(_keyboardLayout, kTISPropertyUnicodeKeyLayoutData);
        _uchrData = (UCKeyboardLayout *)CFDataGetBytePtr(uchr);
        
        _displayModifiedCharacters = [_userDefaults boolForKey:@"default_displayModifiedCharacters"];
        [_userDefaults addObserver:self
                        forKeyPath:@"default_displayModifiedCharacters"
                           options:NSKeyValueObservingOptionNew
                           context:NULL];
        [self configureInputSourceObserver];
    }

    return self;
}

- (void)dealloc
{
    [_userDefaults removeObserver:self forKeyPath:@"default_displayModifiedCharacters"];
    [self removeInputSourceObserver];
    CFRelease(_keyboardLayout);
}

#pragma mark - TIS InputSourceObserver

- (void)configureInputSourceObserver
{
    if (_inputSourceChangeObserved)
        return;

    CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(),
                                    (__bridge const void *)self,
                                    _onSelectedKeyboardInputSourceChanged,
                                    kTISNotifySelectedKeyboardInputSourceChanged,
                                    NULL,
                                    CFNotificationSuspensionBehaviorCoalesce);
    _inputSourceChangeObserved = YES;
}

- (void)removeInputSourceObserver
{
    if (!_inputSourceChangeObserved)
        return;

    CFNotificationCenterRemoveObserver(CFNotificationCenterGetDistributedCenter(),
                                       (__bridge const void *)self,
                                       kTISNotifySelectedKeyboardInputSourceChanged,
                                       NULL);
    _inputSourceChangeObserved = NO;
}

#pragma mark - NSUserDefaults Observer

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"default_displayModifiedCharacters"]) {
        id newValue = change[NSKeyValueChangeNewKey];
        if ([newValue respondsToSelector:@selector(boolValue)]) {
            self.displayModifiedCharacters = [newValue boolValue];
        }
    }
}

#pragma mark - Value Transformer

- (NSDictionary *)_specialKeys
{
    static NSDictionary *d = nil;
    if (d == nil) {
        d = [[NSDictionary alloc] initWithObjectsAndKeys:
             UTF8("\xe2\x87\xa1"), @126, // up
             UTF8("\xe2\x87\xa3"), @125, // down
             UTF8("\xe2\x87\xa2"), @124, // right
             UTF8("\xe2\x87\xa0"), @123, // left
             UTF8("\xe2\x87\xa5"), @48,  // tab
             UTF8("\xe2\x8e\x8b"), @53,  // escape
             UTF8("\xe2\x8c\xa7"), @71,  // clear
             UTF8("\xe2\x8c\xab"), @51,  // delete
             UTF8("\xe2\x8c\xa6"), @117, // forward delete
             UTF8("?\xe2\x83\x9d"), @114, // help
             UTF8("\xe2\x86\x96"), @115, // home
             UTF8("\xe2\x86\x98"), @119, // end
             UTF8("\xe2\x87\x9e"), @116, // pgup
             UTF8("\xe2\x87\x9f"), @121, // pgdn
             UTF8("\xe2\x86\xa9"), @36,  // return
             UTF8("\xe2\x86\xa9"), @76,  // numpad enter
             UTF8("\xf0\x9f\x94\x85"), @145, // low brightness
             UTF8("\xf0\x9f\x94\x86"), @144, // high brightness
             UTF8("\xf0\x9f\x96\xa5"), @160, // mission control
             UTF8("\xf0\x9f\x9a\x80"), @131, // launcher
             UTF8("\xf0\x9f\x94\x8d"), @177, // spotlight key (left-pointing magnifying glass)
             UTF8("\xf0\x9f\x8e\xa4"), @176, // dictation key (microphone)
             UTF8("\xe2\x8f\xbe"), @178,     // focus key (unicode power sleep symbol)
             UTF8("\xe2\x90\xa3\xe2\x80\x8b"), @49, // space
             @"fn ", @179,  // fn key (could also be globe symbol on newer keyboards)
             @"F1 ", @122,  // F1
             @"F2 ", @120,  // F2
             @"F3 ", @99,   // F3
             @"F4 ", @118,  // F4
             @"F5 ", @96,   // F5
             @"F6 ", @97,   // F6
             @"F7 ", @98,   // F7
             @"F8 ", @100,  // F8
             @"F9 ", @101,  // F9
             @"F10 ", @109, // F10
             @"F11 ", @103, // F11
             @"F12 ", @111, // F12
             @"F13 ", @105, // F13
             @"F14 ", @107, // F14
             @"F15 ", @113, // F15
             @"F16 ", @106, // F16
             @"F17 ", @64,  // F17
             @"F18 ", @79,  // F18
             @"F19 ", @80,  // F19
             @"F20 ", @90,  // F20
             @"英数", @0x66, // eisū key, JIS keyboards only
             @"かな", @0x68, // kana key, JIS keyboards only
             nil];
    }
    return d;
}

- (id)transformedValue:(KCKeycastrEvent *)event
{
    NSEventModifierFlags _modifiers = event.modifierFlags;
    BOOL hasOptionModifier = _modifiers & NSEventModifierFlagOption;
    BOOL hasShiftModifier = _modifiers & NSEventModifierFlagShift;
    BOOL isCommand = _modifiers & (NSEventModifierFlagControl | NSEventModifierFlagCommand);
    
    BOOL needsShiftGlyph = NO;
    
    NSMutableString *mutableResponse = [NSMutableString string];

    if (_modifiers & NSEventModifierFlagControl)
	{
		[mutableResponse appendString:kControlKeyString];
	}

	if (hasOptionModifier && (isCommand || !_displayModifiedCharacters))
	{
		[mutableResponse appendString:kOptionKeyString];
	}

    if (hasShiftModifier)
	{
		if (isCommand)
			[mutableResponse appendString:kShiftKeyString];
		else if (hasOptionModifier && !_displayModifiedCharacters)
            [mutableResponse appendString:kShiftKeyString];
        else
			needsShiftGlyph = !_displayModifiedCharacters;
	}

    if (_modifiers & NSEventModifierFlagCommand)
	{
		if (needsShiftGlyph)
		{
			[mutableResponse appendString:kShiftKeyString];
			needsShiftGlyph = NO;
		}
		[mutableResponse appendString:kCommandKeyString];
	}

    if ([event isKindOfClass:[KCMouseEvent class]]) {
        if (needsShiftGlyph) {
            [mutableResponse appendString:kShiftKeyString];
            needsShiftGlyph = NO;
        }
        [mutableResponse appendString:@"🖱️"];
        return mutableResponse;
    }
    
    KCKeystroke *keystroke = (KCKeystroke *)event;

    // check for bare shift-tab as left tab special case
    if (hasShiftModifier && !keystroke.isCommand && !hasOptionModifier)
    {
        if (keystroke.keyCode == 48) {
            [mutableResponse appendString:kLeftTabString];
            return mutableResponse;
        }
    }

    if (needsShiftGlyph) {
        [mutableResponse appendString:kShiftKeyString];
        needsShiftGlyph = NO;
    }
    
    void(^appendModifiers)(BOOL) = ^(BOOL append) {
        if (append && !keystroke.isCommand) {
            if (hasOptionModifier) {
                [mutableResponse appendString:kOptionKeyString];
            }
            if (hasShiftModifier) {
                [mutableResponse appendString:kShiftKeyString];
            }
        }
    };
    
    NSString *specialKeyString = [[self _specialKeys] objectForKey:@(keystroke.keyCode)];
    if (specialKeyString)
    {
        appendModifiers(_displayModifiedCharacters);
		[mutableResponse appendString:specialKeyString];
        return mutableResponse;
	}

    if (_displayModifiedCharacters && !isCommand) {
        if (keystroke.characters.length > 0) {
            [mutableResponse appendString:keystroke.characters];
        } else {
            appendModifiers(_displayModifiedCharacters);
            [mutableResponse appendString:[self translatedCharacterForKeystroke:keystroke]];
        }
    } else {
        [mutableResponse appendString:[self translatedCharacterForKeystroke:keystroke]];
    }
    
    // Commands and shifted keystrokes should be uppercased
    if (isCommand || hasShiftModifier)
    {
        // Unless it is a special case - do not shift keycode 27
        if (keystroke.keyCode != 27) {
            mutableResponse = [[mutableResponse uppercaseString] mutableCopy];
        }
	}
	
	return mutableResponse;
}

- (NSString *)translatedCharacterForKeystroke:(KCKeystroke *)keystroke {
    if ([self shouldReturnOriginalCharactersForKeyCode:keystroke.keyCode 
                                            characters:keystroke.characters] && keystroke.isCommand) {
        return keystroke.characters;
    }
    return [self translateKeyCode:keystroke.keyCode];
}

- (BOOL)shouldReturnOriginalCharactersForKeyCode:(uint16_t)keyCode characters:(NSString *)characters {
    return (keyCode == 27 && [characters isEqual:@"ß"]);
}

- (NSString *)translateKeyCode:(uint16_t)keyCode {
    static UInt32 deadKeyState = 0;
    UniCharCount maxLength = 4, length;
    UniChar unicodeString[4];
    UCKeyTranslate(_uchrData, keyCode, kUCKeyActionDisplay, 0, LMGetKbdType(), kUCKeyTranslateNoDeadKeysBit, &deadKeyState, maxLength, &length, unicodeString);
    return [NSString stringWithCharacters:unicodeString length:length];
}

@end
