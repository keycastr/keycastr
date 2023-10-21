//
//  KCMouseEventVisualizerTests.m
//  KCVisualizerTests
//
//  Created by Andrew Kitchen on 2023-08-25.
//

#import <XCTest/XCTest.h>
#import "KCMouseEventVisualizer.h"

@interface KCMouseEventVisualizerTests : XCTestCase

@property (strong, nonatomic) KCMouseEventVisualizer *visualizer;

@end

@implementation KCMouseEventVisualizerTests

- (void)setUp {
    self.visualizer = [[KCMouseEventVisualizer alloc] init];
}

- (void)tearDown {
    self.visualizer = nil;
}

- (void)testForwardingMouseEvents {
//     NSLog(@"================> mouseDisplayOptionNames: %@", self.visualizer.mouseDisplayOptionNames);
    //
    // mouseDisplayOptionNames: (
    // None,
    // "with mouse pointer",
    // "with current visualizer",
    // "with pointer and visualizer"
    // )
    //
}

@end
