//  Copyright (c) 2024 Andrew Kitchen
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
#import "KCDefaultVisualizer.h"

@interface KCDefaultVisualizerTests : XCTestCase
@property (nonatomic, strong) KCDefaultVisualizer *visualizer;
@end

@interface KCDefaultVisualizer (KCDefaultVisualizerTests)
- (void)configureDisplayModeWithDefaults:(NSUserDefaults *)userDefaults;
@end

@implementation KCDefaultVisualizerTests

- (void)setUp {
	[KCVisualizer loadPluginsFromDirectory:[[NSBundle bundleForClass:[self class]] builtInPlugInsPath]];
    _visualizer = [KCVisualizer visualizerWithName:@"Default"];
}

- (void)tearDown {
	[KCVisualizer unloadPlugins];
}

- (void)performTargetAction:(NSControl *)control {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [control.target performSelector:control.action withObject:control];
#pragma clang diagnostic pop
}

- (void)test_settingAndRetrievingDisplayOptions {
    NSButton *commandKeysOnlyButton = _visualizer.preferencesView.commandKeysOnlyButton;
    NSButton *allModifiedKeysButton = _visualizer.preferencesView.allModifiedKeysButton;
    NSButton *allKeysButton = _visualizer.preferencesView.allKeysButton;

    [self performTargetAction:commandKeysOnlyButton];
    XCTAssertTrue([_visualizer shouldOnlyDisplayCommandKeys]);
    XCTAssertFalse([_visualizer shouldOnlyDisplayModifiedKeys]);

    [self performTargetAction:allModifiedKeysButton];
    XCTAssertFalse([_visualizer shouldOnlyDisplayCommandKeys]);
    XCTAssertTrue([_visualizer shouldOnlyDisplayModifiedKeys]);

    [self performTargetAction:allKeysButton];
    XCTAssertFalse([_visualizer shouldOnlyDisplayCommandKeys]);
    XCTAssertFalse([_visualizer shouldOnlyDisplayModifiedKeys]);
}

- (void)testLoadingDefaults {
	NSUserDefaults *exampleDefaults = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass([self class])];
	
	[exampleDefaults setBool:YES forKey:@"default.commandKeysOnly"];
	[_visualizer configureDisplayModeWithDefaults:exampleDefaults];
	XCTAssertTrue([_visualizer shouldOnlyDisplayCommandKeys]);
	[exampleDefaults setBool:NO forKey:@"default.commandKeysOnly"];
	
	[exampleDefaults setBool:YES forKey:@"default.allModifiedKeys"];
	[_visualizer configureDisplayModeWithDefaults:exampleDefaults];
	XCTAssertTrue([_visualizer shouldOnlyDisplayModifiedKeys]);
	[exampleDefaults setBool:NO forKey:@"default.allModifiedKeys"];
}

@end
