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

- (void)test_KCKeystroke_convertsAlphaCharactersShifted {
    // cmd-opt-shift-]
//    KCKeystroke *keystroke = [[KCKeystroke alloc] init
}

- (void)test_KCKeystroke_convertsNonCommandShiftTabToLeftTab {
    // cmd-opt-shift-]
//    KCKeystroke *keystroke = [[KCKeystroke alloc] init
}

- (void)test_KCKeystroke_convertsForwardDelete {

}

- (void)test_KCKeystroke_convertsCapitalizedCommandStrings {

}

- (void)test_KCKeystroke_convertsOptionComboToKeycap {

}

- (void)test_KCKeystroke_cmdOptionComboConvertsToKeycap {

}

- (void)test_KCKeystroke_shiftCmdEqualsConvertsToPlus {

}

- (void)test_KCKeystroke_shiftCmdMinusConvertsToMinus {

}


@end
