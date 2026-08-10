//  Copyright (c) 2020-2024 Andrew Kitchen
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  *    Redistributions of source code must retain the above copyright notice, this
//      list of conditions and the following disclaimer.
//  *    Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation
//      and/or other materials provided with the distribution.
//  *    Neither the name KeyCastr nor the names of its contributors may be used to
//      endorse or promote products derived from this software without specific
//      prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THKCVisualizerTestsE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <XCTest/XCTest.h>
#import <KCVisualizer/KCKeystroke.h>
#import <KCVisualizer/KCEventTransformer.h>

/**
 NOTE: This is not a comprehensive set of tests, but serves as a sanity check for handling commands and whether to display or apply modifiers.

 These tests were written assuming a US-English layout. They may break when run in other locales unless the keyboard layout is overridden.

 The correct ordering for printing out modifiers should be Control-Option-Shift-Command, according to how they're displayed in menus within Apple's apps.
 */
@interface KCKeystrokeConversionTests : XCTestCase
@property (nonatomic, strong) KCKeystroke *keystroke;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) KCEventTransformer *eventTransformer;
@end

@implementation KCKeystrokeConversionTests

@synthesize keystroke = keystroke, userDefaults = userDefaults, eventTransformer = eventTransformer;

- (KCKeystroke *)keystrokeWithKeyCode:(unsigned short)keyCode modifiers:(NSEventModifierFlags)modifiers characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers {
    NSEvent *fakeEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown
                                          location:NSZeroPoint
                                     modifierFlags:modifiers
                                         timestamp:NSDate.timeIntervalSinceReferenceDate
                                      windowNumber:0
                                           context:nil
                                        characters:characters
                       charactersIgnoringModifiers:charactersIgnoringModifiers
                                         isARepeat:NO
                                           keyCode:keyCode];
    return [[KCKeystroke alloc] initWithNSEvent:fakeEvent];
}

- (void)setUp {
    [super setUp];
    
    // Use the current user's layout. Ultimately we need helper code to obtain different layouts and use them for testing.
    TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();
    
    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass([self class])];
    eventTransformer = [[KCEventTransformer alloc] initWithKeyboardLayout:currentLayout userDefaults:userDefaults];

}

- (void)tearDown {
    [super tearDown];
    [userDefaults removeObjectForKey:@"default_displayModifiedCharacters"];
}

#pragma mark - Numbers

- (void)test_KCKeystroke_distinguishesNumericKeypadKeys {
    // Arrange
    NSDictionary<NSNumber *, NSString *> *expectedStringsByKeyCode = @{
        @(kVK_ANSI_KeypadDecimal): @"⊞.",
        @(kVK_ANSI_KeypadMultiply): @"⊞*",
        @(kVK_ANSI_KeypadPlus): @"⊞+",
        @(kVK_ANSI_KeypadClear): @"⊞⌧",
        @(kVK_ANSI_KeypadDivide): @"⊞/",
        @(kVK_ANSI_KeypadEnter): @"⊞↩",
        @(kVK_ANSI_KeypadMinus): @"⊞-",
        @(kVK_ANSI_KeypadEquals): @"⊞=",
        @(kVK_ANSI_Keypad0): @"⊞0",
        @(kVK_ANSI_Keypad1): @"⊞1",
        @(kVK_ANSI_Keypad2): @"⊞2",
        @(kVK_ANSI_Keypad3): @"⊞3",
        @(kVK_ANSI_Keypad4): @"⊞4",
        @(kVK_ANSI_Keypad5): @"⊞5",
        @(kVK_ANSI_Keypad6): @"⊞6",
        @(kVK_ANSI_Keypad7): @"⊞7",
        @(kVK_ANSI_Keypad8): @"⊞8",
        @(kVK_ANSI_Keypad9): @"⊞9",
        @(kVK_JIS_KeypadComma): @"⊞,"
    };

    for (NSNumber *keyCode in expectedStringsByKeyCode) {
        keystroke = [self keystrokeWithKeyCode:keyCode.unsignedShortValue
                                     modifiers:0
                                     characters:@""
                            charactersIgnoringModifiers:@""];

        // Act
        NSString *convertedString = [eventTransformer transformedValue:keystroke];

        // Assert
        XCTAssertEqualObjects(convertedString, expectedStringsByKeyCode[keyCode]);
    }
}

- (void)test_KCKeystroke_keepsMainKeyboardKeysUnprefixed {
    // Arrange
    NSDictionary<NSNumber *, NSString *> *expectedStringsByKeyCode = @{
        @(kVK_ANSI_1): @"1",
        @(kVK_ANSI_Period): @".",
        @(kVK_Return): @"↩"
    };

    for (NSNumber *keyCode in expectedStringsByKeyCode) {
        NSString *expectedString = expectedStringsByKeyCode[keyCode];
        keystroke = [self keystrokeWithKeyCode:keyCode.unsignedShortValue
                                     modifiers:0
                                     characters:expectedString
                            charactersIgnoringModifiers:expectedString];

        // Act
        NSString *convertedString = [eventTransformer transformedValue:keystroke];

        // Assert
        XCTAssertEqualObjects(convertedString, expectedString);
    }
}

- (void)test_KCKeystroke_convertsCtrlNumberToNumber {
    // ctrl-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:262401 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃7");
}

- (void)test_KCKeystroke_convertsShiftNumberToShiftNumber {
    // shift-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:131330 characters:@"&" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⇧7");
}

- (void)test_KCKeystroke_convertsCtrlShiftNumberToNumber {
    // ctrl-shift-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:393475 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧7");
}

- (void)test_KCKeystroke_convertsCmdNumberToNumber {
    // cmd-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:1048840 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌘7");
}

- (void)test_KCKeystroke_convertsCmdShiftNumberToNumber {
    // cmd-shift-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:1179914 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⇧⌘7");
}

- (void)test_KCKeystroke_convertsCmdOptNumberToNumber {
    // cmd-opt-7
    keystroke = [self keystrokeWithKeyCode: 26 modifiers: 1573160 characters:@"¶" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⌘7");
}

- (void)test_KCKeystroke_convertsShiftOptionNumberToNumber {
    // shift-opt-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:655650 characters:@"»" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⇧7");
}

- (void)test_KCKeystroke_convertsCmdOptShiftNumberToShiftedNumber {
    // cmd-opt-shift-7
    keystroke = [self keystrokeWithKeyCode: 26 modifiers: 1704234 characters:@"‡" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⇧⌘7");
}


#pragma mark - Letters

- (void)test_KCKeystroke_convertsCtrlLetterToUppercaseLetter {
    // ctrl-A
    keystroke = [self keystrokeWithKeyCode:0 modifiers:262401 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃A");
}

- (void)test_KCKeystroke_convertsCtrlShiftLetterToLetter {
    // ctrl-shift-A
    keystroke = [self keystrokeWithKeyCode:0 modifiers:393475 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧A");
}

- (void)test_KCKeystroke_convertsCtrlShiftCmdLetterToLetter {
    // ctrl-shift-cmd-A
    keystroke = [self keystrokeWithKeyCode:0 modifiers:1442059 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧⌘A");
}

- (void)test_KCKeystroke_convertsCtrlOptLetterToUppercaseLetter {
    // crtl-opt-A
    keystroke = [self keystrokeWithKeyCode:0 modifiers:786721 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥A");
}

- (void)test_KCKeystroke_convertsCtrlOptShiftLetterToLetter {
    // ctrl-opt-shift-A
    keystroke = [self keystrokeWithKeyCode:0 modifiers:917795 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥⇧A");
}

- (void)test_KCKeystroke_displaysOptLetterByDefault {
    // opt-U
    keystroke = [self keystrokeWithKeyCode:32 modifiers:524576 characters:@"" charactersIgnoringModifiers:@"u"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥U");
}

#pragma mark - Function Row

- (void)test_KCKeystroke_convertsFnF1ToBrightnessDecrease {
    keystroke = [self keystrokeWithKeyCode:145 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🔅");
}

- (void)test_KCKeystroke_convertsFnF2ToBrightnessIncrease {
    keystroke = [self keystrokeWithKeyCode:144 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🔆");
}

- (void)test_KCKeystroke_convertsFnF3ToMissionControl {
    keystroke = [self keystrokeWithKeyCode:160 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🖥");
}

- (void)test_KCKeystroke_convertsFnF4ToLauncher {
    keystroke = [self keystrokeWithKeyCode:131 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🚀");
}

#pragma mark - JIS layout

- (void)test_KCKeystroke_convertsEisūKey {
    keystroke = [self keystrokeWithKeyCode:102 modifiers:0 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"英数");
}

- (void)test_KCKeystroke_convertsKanaKey {
    keystroke = [self keystrokeWithKeyCode:104 modifiers:0 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"かな");
}

#pragma mark - Displaying keycaps vs. modified characters

- (void)test_displayingKeycapsVsModifiedKeys {
    // shift-opt-7
    keystroke = [self keystrokeWithKeyCode:26 modifiers:655650 characters:@"»" charactersIgnoringModifiers:@"7"];

    // shift-opt-7 transforms to "»" when default_displayModifiedCharacters is set to YES
    [userDefaults setBool:YES forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"»");

    // shift-opt-7 transforms to "⌥⇧7" when default_displayModifiedCharacters is set to NO
    [userDefaults setBool:NO forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥⇧7");
}

#pragma mark - Special Cases

- (void)test_tabKey {
    // tab characters and charactersIgnoringModifiers fields are UTF8 "\t"
    keystroke = [self keystrokeWithKeyCode:48 modifiers:256 characters:@"\t" charactersIgnoringModifiers:@"\t"];
    XCTAssertEqualObjects([keystroke convertToString], @"⇥");
}

- (void)test_shiftTab {
    // shift-tab characters and charactersIgnoringModifiers fields are UTF8 "\U00000019"
    // it is not possble use Objective-C @ literals with \U000000xx syntax for many 2 byte ASCII characters
    // https://stackoverflow.com/a/27697100
    keystroke = [self keystrokeWithKeyCode:48 modifiers:131330 characters:[NSString stringWithFormat:@"%C", 0x00000019] charactersIgnoringModifiers:[NSString stringWithFormat:@"%C", 0x00000019]];
    XCTAssertEqualObjects([keystroke convertToString], @"⇤");
}

#pragma mark - US English - Special Cases with Modifiers

- (void)test_optionShiftUp {
    // option-shift-up (and by extension, all direction keys & special cases) should show their modifiers with displayModifiedCharacters mode both on and off
    // opt-shift-up
    keystroke = [self keystrokeWithKeyCode:126 modifiers:11141410 characters:[NSString stringWithFormat:@"%lu", 0x00006000002f5c00] charactersIgnoringModifiers:[NSString stringWithFormat:@"%lu", 0x00006000002f5c00]];
    
    [userDefaults setBool:NO forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥⇧⇡");
    
    [userDefaults setBool:YES forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥⇧⇡");
}

- (void)test_optionUSpecialCase {
    // opt-u should show opt-u with displayModifiedCharacters on
    keystroke = [self keystrokeWithKeyCode:32 modifiers:524576 characters:@"" charactersIgnoringModifiers:@"u"];

    [userDefaults setBool:YES forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥u");
}

- (void)test_optionESpecialCase {
    keystroke = [self keystrokeWithKeyCode:14 modifiers:524576 characters:@"" charactersIgnoringModifiers:@"e"];
    
    [userDefaults setBool:NO forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥E");
    
    [userDefaults setBool:YES forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥e");
}

- (void)test_optionBacktickSpecialCase {
    keystroke = [self keystrokeWithKeyCode:50 modifiers:524576 characters:@"" charactersIgnoringModifiers:@"`"];
    
    [userDefaults setBool:NO forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥`");

    [userDefaults setBool:YES forKey:@"default_displayModifiedCharacters"];
    XCTAssertEqualObjects([eventTransformer transformedValue:keystroke], @"⌥`");
}

#pragma mark - German - Special Case

- (void)test_commandßDisplaysCommandß {
    // command-ß on a German keyboard layout - Built-in captalization is SS and there is a special glyph for a capitalized sharp S.
    // In order to avoid confusion, fall back to displaying the keycap.
    keystroke = [self keystrokeWithKeyCode:27 modifiers:1048840 characters:@"ß" charactersIgnoringModifiers:@"ß"];
    XCTAssertEqualObjects([keystroke convertToString], @"⌘ß");
}

@end
