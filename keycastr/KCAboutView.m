//    Copyright (c) 2026 Daniel Costa
//
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification,
//    are permitted provided that the following conditions are met:
//
//    *    Redistributions of source code must retain the above copyright notice, this
//        list of conditions and the following disclaimer.
//    *    Redistributions in binary form must reproduce the above copyright notice,
//        this list of conditions and the following disclaimer in the documentation
//        and/or other materials provided with the distribution.
//    *    Neither the name KeyCastr nor the names of its contributors may be used to
//        endorse or promote products derived from this software without specific
//        prior written permission.
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

#import "QuartzCorePrivate.h"

@interface KCAboutView : NSView
@end

@implementation KCAboutView {
    CALayer *_rootLayer;
    CAStateController *_stateController;
    CAState *_pressedState;
    
    id _eventMonitor;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"About" withExtension:@"ca"];
    NSError *outError;
    
    CAPackage *package = [CAPackage packageWithContentsOfURL:url type:kCAPackageTypeCAMLBundle options:nil error:&outError];
    if (outError) {
        NSLog(@"%@", [outError description]);
        
        return;
    }
    
    _rootLayer = package.rootLayer;
    
    _stateController = [[CAStateController alloc] initWithLayer:_rootLayer];
    [_stateController setInitialStatesOfLayer:package.rootLayer transitionSpeed:0.0];
    
    _pressedState = [_rootLayer valueForKey:@"states"][0];
    
    self.wantsLayer = YES;
    self.layer = package.rootLayer;
    
    // Track mouse hovering over app logo
    CGRect appLogoRect = CGRectMake(84, 24, 94, 94);
    
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:appLogoRect
                                                                options:(NSTrackingMouseEnteredAndExited | NSTrackingActiveAlways)
                                                                  owner:self
                                                               userInfo:nil];
    
    [self addTrackingArea:trackingArea];
}

- (void)setPressedState:(BOOL)pressed {
    if (pressed) {
        [_stateController setState:_pressedState ofLayer:_rootLayer transitionSpeed:1.0];
    }
    else {
        [_stateController setState:nil ofLayer:_rootLayer transitionSpeed:1.0];
    }
}

// MARK: Event monitoring

- (void)removeMonitor {
    if (_eventMonitor) {
        [NSEvent removeMonitor:_eventMonitor];
        _eventMonitor = nil;
    }
}

- (void)viewDidMoveToWindow {
    [super viewDidMoveToWindow];
    
    if (self.window) {
        __weak typeof(self) weakSelf = self;
        
        // Track command button being held
        _eventMonitor = [NSEvent addLocalMonitorForEventsMatchingMask:NSEventMaskFlagsChanged
                                              handler:^NSEvent * _Nullable(NSEvent * _Nonnull event) {
            BOOL heldCommand = event.modifierFlags & NSEventModifierFlagCommand;
            
            [weakSelf handleCommandPress:heldCommand];
            
            return event;
        }];
    }
    else {
        [self removeMonitor];
    }
}

- (void)dealloc {
    [self removeMonitor];
}

// MARK: Event handling

- (void)handleCommandPress:(BOOL)heldCommand {
    [self setPressedState:heldCommand];
}

- (void)mouseEntered:(NSEvent *)event {
    [self setPressedState:YES];
}
- (void)mouseExited:(NSEvent *)event {
    [self setPressedState:NO];
}
@end


@implementation KCAboutView (Window)
- (BOOL)mouseDownCanMoveWindow {
    return YES;
}
@end
