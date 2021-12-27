//    Copyright (c) 2021 Andrew Kitchen
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification,
//    are permitted provided that the following conditions are met:
//
//    *    Redistributions of source code must retain the above copyright notice, this
//         list of conditions and the following disclaimer.
//    *    Redistributions in binary form must reproduce the above copyright notice,
//         this list of conditions and the following disclaimer in the documentation
//         and/or other materials provided with the distribution.
//    *    Neither the name KeyCastr nor the names of its contributors may be used to
//         endorse or promote products derived from this software without specific
//         prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//    IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#if !__has_feature(objc_arc)
#error "ARC is required for this compilation unit -- enable with --fobjc-arc"
#endif

#import <AppKit/AppKit.h>
#import <QuartzCore/QuartzCore.h>
#import "KCMouseEventVisualizer.h"
#import "KCMouseEvent.h"
#import "NSUserDefaults+Utility.h"
#import "KCKeycastrEvent.h"

static CGFloat const kKCMouseVisualizerRadius = 22.0;

@interface KCMouseVisualizerWindow : NSWindow

- (void)updateWithMouseEvent:(KCMouseEvent *)event;

@end

#pragma mark - KCMouseEventVisualizer

@interface KCMouseEventVisualizer ()

@property (nonatomic, strong) NSArray<NSString *> *mouseOptionNames;
@property (nonatomic, assign) NSUInteger selectedMouseOptionIndex;

@end

@implementation KCMouseEventVisualizer {
    KCMouseVisualizerWindow *_window;
}

- (instancetype)init {
    if (!(self = [super init])) {
        return nil;
    }

    _mouseOptionNames = @[@"None",
            @"With Mouse Pointer",
//             @"With Current Visualizer",
//             @"With Pointer and Visualizer"
    ];

    // TODO: set _selectedMouseOptionIndex from NSUserDefaults

    CGFloat diameter = 2 * kKCMouseVisualizerRadius;
    _window = [[KCMouseVisualizerWindow alloc] initWithContentRect:NSMakeRect(0, 0, diameter, diameter)
                                                         styleMask:NSWindowStyleMaskBorderless
                                                           backing:NSBackingStoreBuffered
                                                             defer:NO];
    [_window orderFrontRegardless];

    return self;
}

- (BOOL)isMouseUp:(KCMouseEvent *)mouseEvent {
    return mouseEvent.type == NSEventTypeLeftMouseUp
    || mouseEvent.type == NSEventTypeRightMouseUp
    || mouseEvent.type == NSEventTypeOtherMouseUp;
}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {
    if (self.selectedMouseOptionIndex > 0 || [self isMouseUp:mouseEvent]) {
        [_window updateWithMouseEvent:mouseEvent];
    }

    // TODO: delegate back out so that the currentVisualizer can also show the event, if supported & enabled
}

#pragma mark - KCMouseOptionsProvider

- (NSString *)currentMouseOptionName {
    return [self.mouseOptionNames objectAtIndex:self.selectedMouseOptionIndex];
}

- (void)setCurrentMouseOptionName:(NSString *)currentMouseOptionName {
    NSLog(@"================> currentMouseOptionName: %@", currentMouseOptionName);

    self.selectedMouseOptionIndex = [self.mouseOptionNames indexOfObject:currentMouseOptionName];
}

- (void)setSelectedMouseOptionIndex:(NSUInteger)selectedMouseOptionIndex {
    // TODO: also set in NSUserDefaults
    _selectedMouseOptionIndex = selectedMouseOptionIndex;
}

@end

#pragma mark - KCMouseVisualizerWindow

@interface KCMouseVisualizerWindow ()

@property (nonatomic, strong) CAShapeLayer *circle;
@property (nonatomic, strong) CABasicAnimation *animation;

@end

@implementation KCMouseVisualizerWindow

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backing defer:(BOOL)defer {
    if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:backing defer:defer]))
        return nil;

    [self setLevel:NSScreenSaverWindowLevel];
    [self setOpaque:NO];

    [self setBackgroundColor:[NSColor clearColor]];
    [self setAlphaValue:1];

    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];

    return self;
}

- (void)updateWithMouseEvent:(KCMouseEvent *)event {

    if (!self.circle) {
        CGFloat diameter = 2 * kKCMouseVisualizerRadius;
        CGFloat lineWidth = 2.0;

        self.circle = [CAShapeLayer layer];
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSMakeRect(lineWidth, lineWidth, diameter - 2 * lineWidth, diameter - 2 * lineWidth)
                                                             xRadius:kKCMouseVisualizerRadius
                                                             yRadius:kKCMouseVisualizerRadius];
        self.circle.path = [self CGPathWithPath:path];
        self.circle.strokeColor = [[NSUserDefaults standardUserDefaults] colorForKey:@"default.bezelColor"].CGColor;
        self.circle.fillColor = NSColor.clearColor.CGColor;
        self.circle.lineWidth = lineWidth;
        self.circle.opacity = 0.0;

        [self.contentView.layer addSublayer:self.circle];
    }

    switch (event.type) {
        case NSEventTypeLeftMouseDown:
        case NSEventTypeRightMouseDown:
        case NSEventTypeOtherMouseDown: {
            self.circle.opacity = 1.0;

            if (self.animation == nil) {
                self.animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                self.animation.fromValue = @1.0;
                self.animation.toValue = @0.0;
            }
            // fall through
        }
        case NSEventTypeLeftMouseDragged:
        case NSEventTypeRightMouseDragged:
        case NSEventTypeOtherMouseDragged: {
            NSPoint origin = NSMakePoint(event.locationInWindow.x - kKCMouseVisualizerRadius,
                                         event.locationInWindow.y - kKCMouseVisualizerRadius);
            [self setFrameOrigin:origin];

            break;
        }

        case NSEventTypeLeftMouseUp:
        case NSEventTypeRightMouseUp:
        case NSEventTypeOtherMouseUp: {
            if (self.animation) {
                [self.circle addAnimation:self.animation forKey:@"opacityAnimation"];
                self.animation = nil;
            }
            self.circle.opacity = 0.0;

            break;
        }

        default:
            break;
    }
}

- (CGMutablePathRef)CGPathWithPath:(NSBezierPath *)path {
    CGMutablePathRef cgPath = CGPathCreateMutable();
    NSInteger count = [path elementCount];

    for (NSInteger i = 0; i < count; i++) {
        NSPoint points[3];
        switch ([path elementAtIndex:i associatedPoints:points]) {
            case NSBezierPathElementMoveTo: {
                CGPathMoveToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            }
            case NSBezierPathElementLineTo: {
                CGPathAddLineToPoint(cgPath, NULL, points[0].x, points[0].y);
                break;
            }
            case NSBezierPathElementCurveTo: {
                CGPathAddCurveToPoint(cgPath, NULL, points[0].x, points[0].y, points[1].x, points[1].y, points[2].x, points[2].y);
                break;
            }
            case NSBezierPathElementClosePath: {
                CGPathCloseSubpath(cgPath);
                break;
            }
            default:
                NSAssert(0, @"Invalid NSBezierPathElement");
        }
    }
    return cgPath;
}

@end
