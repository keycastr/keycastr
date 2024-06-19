//  Copyright (c) 2023-2024 Andrew Kitchen
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
