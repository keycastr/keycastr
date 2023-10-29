//
//  KCMouseEventVisualizerTests.m
//  KCVisualizerTests
//
//  Created by Andrew Kitchen on 2023-08-25.
//

#if !__has_feature(objc_arc)
#error "ARC is required for this file -- enable with --fobjc-arc"
#endif

#import <XCTest/XCTest.h>
#import "KCMouseEvent.h"
#import "KCMouseEventVisualizer.h"

@interface KCMouseEventDelegateSpy : NSObject<KCMouseEventVisualizerDelegate>
@property (nonatomic, strong) NSMutableArray<KCMouseEvent *> *eventsReceived;
@end

@implementation KCMouseEventDelegateSpy

- (instancetype)init {
    self = [super init];
    self.eventsReceived = [NSMutableArray array];
    return self;
}

- (void)mouseEventVisualizer:(KCMouseEventVisualizer *)visualizer didNoteMouseEvent:(KCMouseEvent *)mouseEvent { 
    [self.eventsReceived addObject:mouseEvent];
}

@end

#pragma mark -

@interface KCMouseEventVisualizerTests : XCTestCase

@property (strong, nonatomic) KCMouseEventVisualizer *visualizer;
@property (strong, nonatomic) KCMouseEventDelegateSpy *delegate;

@end

@implementation KCMouseEventVisualizerTests

- (void)setUp {
    self.visualizer = [[KCMouseEventVisualizer alloc] init];
    self.delegate = [[KCMouseEventDelegateSpy alloc] init];
    self.visualizer.delegate = self.delegate;
}

- (void)tearDown {
    self.visualizer = nil;
    self.delegate = nil;
}

- (void)testForwardingMouseEvents {
	NSLog(@"================> mouseDisplayOptionNames: %@", self.visualizer.mouseDisplayOptionNames);
	
    KCMouseEvent *fakeMouseEvent = [[KCMouseEvent alloc] initWithNSEvent:nil];
    
    // displayOptionNone
    self.visualizer.selectedMouseDisplayOptionIndex = 0;
    [self.visualizer noteMouseEvent:fakeMouseEvent];

    XCTAssertEqual(0, self.delegate.eventsReceived.count);

    // displayOptionWithPointer
    self.visualizer.selectedMouseDisplayOptionIndex = 1;
    [self.visualizer noteMouseEvent:fakeMouseEvent];

    XCTAssertEqual(0, self.delegate.eventsReceived.count);

    // displayOptionWithCurrentVisualizer
    self.visualizer.selectedMouseDisplayOptionIndex = 2;
    [self.visualizer noteMouseEvent:fakeMouseEvent];

    XCTAssertEqual(1, self.delegate.eventsReceived.count);
    [self.delegate.eventsReceived removeAllObjects];

    // displayOptionWithPointerAndCurrentVisualizer
    self.visualizer.selectedMouseDisplayOptionIndex = 3;
    [self.visualizer noteMouseEvent:fakeMouseEvent];
    
    XCTAssertEqual(1, self.delegate.eventsReceived.count);
}

@end
