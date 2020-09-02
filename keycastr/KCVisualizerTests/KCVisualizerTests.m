//
//  KCVisualizerTests.m
//  KCVisualizerTests
//
//  Created by Andrew Kitchen on 11/9/19.
//

#import <XCTest/XCTest.h>
#import "KCKeystroke.h"


/**
 NOTE: This is not a comprehensive set of tests, but serves as a sanity check for handling letters vs. numbers when certain modifiers are applied.

 The correct ordering for printing out modifiers should be ctrl-option-shift-command, according to how they're displayed in menus within Apple's apps. This means we'll need to adjust all of this once the general heuristic is sorted out.
 */
@interface KCVisualizerTests : XCTestCase

@end

@implementation KCVisualizerTests

#pragma mark - Numbers

- (void)test_KCKeystroke_convertsCtrlNumberToNumber {
    // ctrl-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:26 modifiers:262401 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃7");
}

- (void)test_KCKeystroke_convertsCtrlShiftNumberToNumber {
    // ctrl-shift-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:26 modifiers:393475 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧7");
}

- (void)test_KCKeystroke_convertsCmdNumberToNumber {
    // cmd-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:26 modifiers:1048840 characters:@"7" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌘7");
}

- (void)test_KCKeystroke_convertsCmdShiftNumberToNumber {
    // cmd-shift-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:26 modifiers:1179914 characters:@"7" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⇧⌘7");
}

- (void)test_KCKeystroke_convertsCmdOptNumberToNumber {
    // cmd-opt-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode: 26 modifiers: 1573160 characters:@"¶" charactersIgnoringModifiers:@"7"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⌘7");
}

// Until we come up with a clever way of resolving keycaps, it doesn't seem to be possible to convert to a number here
- (void)test_KCKeystroke_convertsCmdOptShiftNumberToShiftedNumber {
    // cmd-opt-shift-7 -> &
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode: 26 modifiers: 1704234 characters:@"‡" charactersIgnoringModifiers:@"&"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥⇧⌘&");
}


#pragma mark - Letters

- (void)test_KCKeystroke_convertsCtrlLetterToUppercaseLetter {
    // ctrl-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:262401 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃A");
}

- (void)test_KCKeystroke_convertsCtrlShiftLetterToLetter {
    // ctrl-shift-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:393475 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧A");
}

- (void)test_KCKeystroke_convertsCtrlShiftCmdLetterToLetter {
    // ctrl-shift-cmd-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:1442059 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧⌘A");
}

- (void)test_KCKeystroke_convertsCtrlOptLetterToUppercaseLetter {
    // crtl-opt-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:786721 characters:@"\\^A" charactersIgnoringModifiers:@"a"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥A");
}

- (void)test_KCKeystroke_convertsCtrlOptShiftLetterToLetter {
    // ctrl-opt-shift-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:917795 characters:@"\\^A" charactersIgnoringModifiers:@"A"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⌥⇧A");
}

- (void)test_KCKeystroke_convertsOptLetterToLetter {
    // opt-U
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:32 modifiers:524576 characters:nil charactersIgnoringModifiers:@"u"];
    XCTAssertEqualObjects(keystroke.convertToString, @"⌥U");
}

@end
