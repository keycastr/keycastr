//  Copyright (c) 2023 Colin Gray
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  *   Redistributions of source code must retain the above copyright notice, this
//      list of conditions and the following disclaimer.
//  *   Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation
//      and/or other materials provided with the distribution.
//  *   Neither the name KeyCastr nor the names of its contributors may be used to
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

#define MODS_WIDTH 100

#import "MinimalVisualizer.h"
#import "NSBezierPath+RoundedRect.h"
#import "KCKeystroke.h"

@implementation MinimalVisualizerFactory

- (NSString *)visualizerNibName {
    return @"Minimal";
}

- (Class)visualizerClass {
    return [MinimalVisualizer class];
}

- (NSString *)visualizerName {
    return @"Minimal";
}

@end

@implementation MinimalVisualizerView

- (unsigned short)flagsCount  {
    unsigned short count = 0;

	if (_flags & NSEventModifierFlagFunction) {
		count += 1;
	}

    if (_flags & NSEventModifierFlagControl) {
        count += 1;
    }

    if (_flags & NSEventModifierFlagOption) {
        count += 1;
    }

    if (_flags & NSEventModifierFlagShift) {
        count += 1;
    }

    if (_flags & NSEventModifierFlagCommand) {
        count += 1;
    }

    return count;
}

- (void)drawRect:(NSRect)rect {
    NSRect frame = [self frame];
    NSRect bgFrame = [self frame];
    float oneQuarter = floorf(MODS_WIDTH);

    CGFloat x = frame.size.width, y;
    NSSize size;

    [[NSColor clearColor] setFill];
    NSRectFill(frame);

    if (bgFrame.size.width > 0) {
        [[NSColor colorWithCalibratedWhite:0 alpha:0.75] setFill];
        NSBezierPath* bp = [NSBezierPath bezierPath];
        [bp appendRoundedRect:bgFrame radius:10];
        [bp fill];
    }

    NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle alloc] init];
    [ps setAlignment:NSTextAlignmentCenter];

    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2];
    [shadow setShadowOffset:NSMakeSize(2,-2)];

    NSMutableDictionary* attr = [@{
        NSFontAttributeName:            [NSFont boldSystemFontOfSize:80],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:1 alpha:0.8],
        NSShadowAttributeName:          shadow,
        NSParagraphStyleAttributeName:  ps
    } mutableCopy];

	if (_flags & NSEventModifierFlagCommand) {
		NSString* commandKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x98\x01"];
		size = [commandKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[commandKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

	if (_flags & NSEventModifierFlagShift) {
		NSString* shiftKeyString = [NSString stringWithUTF8String:"\xe2\x87\xa7\x01"];
		size = [shiftKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[shiftKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

    if (_flags & NSEventModifierFlagOption) {
        NSString* altKeyString = [NSString stringWithUTF8String:"\xe2\x8c\xa5\x01"];
        size = [altKeyString sizeWithAttributes:attr];
        y = (frame.size.height - size.height) / 2.0;
        x -= oneQuarter;
        [altKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
    }

	if (_flags & NSEventModifierFlagControl) {
		NSString* controlKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x83\x01"];
		size = [controlKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[controlKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

	if (_flags & NSEventModifierFlagFunction) {
		NSString* controlKeyString = [NSString stringWithUTF8String:"fn"];
		size = [controlKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[controlKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}
}

- (void)noteFlagsChanged:(uint32_t)flags {
    _flags = flags;
    NSRect frame = self.frame;
    frame.size.width = MODS_WIDTH * (CGFloat)[self flagsCount];
    self.frame = frame;
    [self setNeedsDisplay:YES];
}

@end

@implementation MinimalVisualizer

- (NSString *)visualizerName {
    return @"Minimal";
}

- (id)init {
    if (!(self = [super init]))
        return nil;

    // autosave frame was not working, despite best efforts. Easy workaround to use defaults instead.
    // (and autosave frame _uses_ defaults anyway so same thing in the end?)
    NSString *frameValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"minimal.savedFrame"];
    NSRect windowFrame = { MODS_WIDTH, 100, 0, 100 };
    if (frameValue) {
        windowFrame = NSRectFromString(frameValue);
    }

    _visualizerWindow = [[NSWindow alloc]
         initWithContentRect:windowFrame
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [_visualizerWindow setLevel:NSScreenSaverWindowLevel];
    [_visualizerWindow setBackgroundColor:[NSColor clearColor]];
    [_visualizerWindow setMovableByWindowBackground:YES];
    [_visualizerWindow setFrame:windowFrame display:NO];
    [_visualizerWindow setOpaque:NO];
    [_visualizerWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];

    _visualizerView = [[MinimalVisualizerView alloc] init];
    [_visualizerView noteFlagsChanged:0];
    [_visualizerWindow setContentView:_visualizerView];

    return self;
}

- (void)showVisualizer:(id)sender {
    [_visualizerWindow orderFront:self];
}

- (void)hideVisualizer:(id)sender {
    [_visualizerWindow orderOut:self];
}

- (void)deactivateVisualizer:(id)sender {
    [_visualizerWindow orderOut:self];
}

- (void)noteFlagsChanged:(uint32_t)flags {
    [_visualizerView noteFlagsChanged:flags];
    NSRect windowFrame = _visualizerWindow.frame;
    NSScreen *screen = _visualizerWindow.screen;
    if (!screen) {
        for (NSScreen *s in NSScreen.screens) {
            if (CGRectContainsPoint(s.frame, windowFrame.origin)) {
                screen = s;
                break;
            }
        }

        if (!screen) {
            screen = NSScreen.screens.firstObject;
        }
    }
    
    NSRect screenFrame = screen.frame;
    CGFloat screenX = windowFrame.origin.x - screenFrame.origin.x;
    if (screenX > screenFrame.size.width / 2) {
        CGFloat right = windowFrame.origin.x + windowFrame.size.width;
        windowFrame.size.width = _visualizerView.frame.size.width;
        windowFrame.origin.x = right - windowFrame.size.width;
    } else {
        windowFrame.size.width = _visualizerView.frame.size.width;
    }
    [_visualizerWindow setFrame:windowFrame display:NO];
    [[NSUserDefaults standardUserDefaults] setValue:NSStringFromRect(_visualizerWindow.frame) forKey:@"minimal.savedFrame"];
}

- (void)noteKeyEvent:(KCKeycastrEvent *)event {}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {}

+ (NSDictionary<NSString *,NSObject *> *)visualizerDefaults {
	return @{};
}

@end
