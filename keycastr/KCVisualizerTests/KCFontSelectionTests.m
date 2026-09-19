//  Copyright (c) 2026 Andrew Kitchen
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
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <XCTest/XCTest.h>
#import <KCVisualizer/KCVisualizer.h>

#import <KCVisualizer/NSUserDefaults+Utility.h>

static NSString *const kFontKey = @"test.fontName";

@interface KCFontSelectionTests : XCTestCase
@end

@implementation KCFontSelectionTests
{
    NSUserDefaults *_defaults;
}

- (void)setUp {
    [super setUp];
    _defaults = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass([self class])];
    [_defaults removeObjectForKey:kFontKey];
}

- (void)tearDown {
    [_defaults removeObjectForKey:kFontKey];
    _defaults = nil;
    [super tearDown];
}

- (void)test_unsetFamilyUsesTheSystemFont {
    XCTAssertEqualObjects([_defaults fontForKey:kFontKey size:16 bold:NO], [NSFont systemFontOfSize:16]);
}

- (void)test_unsetFamilyUsesTheBoldSystemFontWhenBoldIsRequested {
    XCTAssertEqualObjects([_defaults fontForKey:kFontKey size:16 bold:YES], [NSFont boldSystemFontOfSize:16]);
}

// The pop-up stores the empty string for its "System Font" item, since a nil
// value can't be told apart from a key that was never written.
- (void)test_emptyFamilyUsesTheSystemFont {
    [_defaults setObject:@"" forKey:kFontKey];

    XCTAssertEqualObjects([_defaults fontForKey:kFontKey size:16 bold:NO], [NSFont systemFontOfSize:16]);
}

- (void)test_installedFamilyIsHonored {
    NSString *family = [[NSFontManager sharedFontManager] availableFontFamilies].firstObject;
    XCTAssertNotNil(family);
    [_defaults setObject:family forKey:kFontKey];

    NSFont *font = [_defaults fontForKey:kFontKey size:24 bold:NO];

    XCTAssertEqualObjects(font.familyName, family);
    XCTAssertEqualWithAccuracy(font.pointSize, 24, 0.01);
}

// Fonts can be uninstalled or disabled in Font Book after they've been chosen.
- (void)test_familyThatIsNoLongerInstalledFallsBackToTheSystemFont {
    [_defaults setObject:@"A Font That Is Not Installed" forKey:kFontKey];

    XCTAssertEqualObjects([_defaults fontForKey:kFontKey size:16 bold:NO], [NSFont systemFontOfSize:16]);
}

- (NSPopUpButton *)fontPopUpButtonInView:(NSView *)view {
    for (NSView *subview in view.subviews) {
        if ([subview isKindOfClass:[NSPopUpButton class]]) {
            return (NSPopUpButton *)subview;
        }
    }
    return nil;
}

// Minimal isn't copied into the test bundle's plug-ins, so it isn't covered here;
// its preferences view is a plain xib and gets validated when the project builds.
- (void)test_visualizerPreferencesOfferAFontPopUpBoundToTheirOwnKey {
    [KCVisualizer loadPluginsFromDirectory:[[NSBundle bundleForClass:[self class]] builtInPlugInsPath]];

    NSDictionary *fontKeysByVisualizerName = @{@"Default": @"default.fontName", @"Svelte": @"svelte.fontName"};
    for (NSString *name in fontKeysByVisualizerName) {
        id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:name];
        XCTAssertNotNil(visualizer, @"%@ visualizer did not load", name);

        NSPopUpButton *fontPopUpButton = [self fontPopUpButtonInView:[visualizer preferencesView]];
        XCTAssertNotNil(fontPopUpButton, @"%@ preferences have no font pop-up", name);
        XCTAssertEqualObjects([fontPopUpButton valueForKey:@"fontFamilyDefaultsKey"], fontKeysByVisualizerName[name]);

        // "System Font", a separator, and then everything that's installed.
        XCTAssertGreaterThan(fontPopUpButton.numberOfItems, 2, @"%@", name);
        XCTAssertEqualObjects([fontPopUpButton itemAtIndex:0].representedObject, @"", @"%@", name);
    }

    [KCVisualizer unloadPlugins];
}

@end
