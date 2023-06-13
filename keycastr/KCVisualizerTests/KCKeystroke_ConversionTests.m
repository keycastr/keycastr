//
//  KCKeystroke_ConversionTests.m
//  KCKeystroke_ConversionTests
//
//  Created by Andrew Kitchen on 11/9/19.
//

#import <XCTest/XCTest.h>
#import "KCKeystroke.h"


/**
 NOTE: This is not a comprehensive set of tests, but serves as a sanity check for handling letters vs. numbers when certain modifiers are applied.

 These tests were written assuming a US-English layout. They may break when run in other locales unless the keyboard layout is overridden.

 The correct ordering for printing out modifiers should be ctrl-option-shift-command, according to how they're displayed in menus within Apple's apps. This means we'll need to adjust all of this once the general heuristic is sorted out.
 */
@interface KCKeystroke_ConversionTests : XCTestCase

@end

@implementation KCKeystroke_ConversionTests

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

#pragma mark - Numbers

- (void)test_KCKeystroke_convertsCtrlNumberToNumber {
    // ctrl-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:262401 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃7");
}

- (void)test_KCKeystroke_convertsShiftNumberToShiftNumber {
    // shift-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:131330 characters:@"&" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⇧7");
}

- (void)test_KCKeystroke_convertsCtrlShiftNumberToNumber {
    // ctrl-shift-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:393475 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧7");
}

- (void)test_KCKeystroke_convertsCmdNumberToNumber {
    // cmd-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:1048840 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌘7");
}

- (void)test_KCKeystroke_convertsCmdShiftNumberToNumber {
    // cmd-shift-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:1179914 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⇧⌘7");
}

- (void)test_KCKeystroke_convertsCmdOptNumberToNumber {
    // cmd-opt-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode: 26 modifiers: 1573160 characters:@"¶" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⌘7");
}

- (void)test_KCKeystroke_convertsCmdOptShiftNumberToShiftedNumber {
    // cmd-opt-shift-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode: 26 modifiers: 1704234 characters:@"‡" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⇧⌘7");
}


#pragma mark - Letters

- (void)test_KCKeystroke_convertsCtrlLetterToUppercaseLetter {
    // ctrl-A
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:0 modifiers:262401 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃A");
}

- (void)test_KCKeystroke_convertsCtrlShiftLetterToLetter {
    // ctrl-shift-A
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:0 modifiers:393475 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧A");
}

- (void)test_KCKeystroke_convertsCtrlShiftCmdLetterToLetter {
    // ctrl-shift-cmd-A
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:0 modifiers:1442059 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧⌘A");
}

- (void)test_KCKeystroke_convertsCtrlOptLetterToUppercaseLetter {
    // ctrl-opt-A
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:0 modifiers:786721 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥A");
}

- (void)test_KCKeystroke_convertsCtrlOptShiftLetterToLetter {
    // ctrl-opt-shift-A
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:0 modifiers:917795 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥⇧A");
}

- (void)test_KCKeystroke_convertsOptLetterToShiftedLetter {
    // opt-U
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:32 modifiers:524576 characters:@"" charactersIgnoringModifiers:@"u"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥u");
}

- (void)test_KCKeystroke_convertsShiftOptionNumberToNumber {
    // shift-opt-7
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:26 modifiers:655650 characters:@"»" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⇧7");
}

#pragma mark - Function Row

- (void)test_KCKeystroke_convertsFnF1ToBrightnessDecrease {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:145 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🔅");
}

- (void)test_KCKeystroke_convertsFnF2ToBrightnessIncrease {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:144 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🔆");
}

- (void)test_KCKeystroke_convertsFnF3ToMissionControl {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:160 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🖥");
}

- (void)test_KCKeystroke_convertsFnF4ToLauncher {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:131 modifiers:8388864 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"🚀");
}

#pragma mark - JIS layout

- (void)test_KCKeystroke_convertsEisūKey {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:102 modifiers:0 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"英数");
}

- (void)test_KCKeystroke_convertsKanaKey {
    KCKeystroke *keystroke = [self keystrokeWithKeyCode:104 modifiers:0 characters:@"" charactersIgnoringModifiers:@""];
    XCTAssertEqualObjects(keystroke.convertToString, @"かな");
}


@end
