//
//  KCVisualizerTests.m
//  KCVisualizerTests
//
//  Created by Andrew Kitchen on 11/9/19.
//

#import <XCTest/XCTest.h>
#import "KCKeystroke.h"

@interface KCVisualizerTests : XCTestCase

@end

@implementation KCVisualizerTests

- (void)test_KCKeystroke_convertsNonAlphanumericCharactersUnshifted {
    // cmd-shift-]
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:30 modifiers:1179914 characters:@"]" charactersIgnoringModifiers:@"}"];

    XCTAssertNotNil(keystroke);
    XCTAssertEqualObjects(keystroke.characters, @"]");

    XCTAssertEqualObjects(keystroke.convertToString, @"⇧⌘]");
}

- (void)test_KCKeystroke_convertsShiftedNumberCommandsToNumber {
    // cmd-shift-7
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:26 modifiers:1179914 characters:@"7" charactersIgnoringModifiers:@"&"];

    XCTAssertEqualObjects(keystroke.convertToString, @"⇧⌘7");
}

- (void)test_KCKeystroke_convertsCtrlShiftedCommandLetterToLetter {
    // ctrl-shift-cmd-A
    KCKeystroke *keystroke = [[KCKeystroke alloc] initWithKeyCode:0 modifiers:1442059 characters:@"\\^A" charactersIgnoringModifiers:@"A"];

    XCTAssertEqualObjects(keystroke.convertToString, @"⌃⇧⌘A");
}

@end
