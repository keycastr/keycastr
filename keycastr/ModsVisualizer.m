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

#import "ModsVisualizer.h"
#import "NSBezierPath+RoundedRect.h"
#import "KCKeystroke.h"

@implementation ModsVisualizerFactory

- (NSString *)visualizerNibName {
    return @"Mods";
}

- (Class)visualizerClass {
    return [ModsVisualizer class];
}

- (NSString *)visualizerName {
    return @"Mods";
}

@end

@implementation ModsVisualizerView

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

    NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
    [shadow setShadowColor:[NSColor blackColor]];
    [shadow setShadowBlurRadius:2];
    [shadow setShadowOffset:NSMakeSize(2,-2)];

    NSMutableDictionary* attr = [@{
        NSFontAttributeName:            [NSFont boldSystemFontOfSize:80],
        NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:1 alpha:0.8],
        NSShadowAttributeName:          shadow,
        NSParagraphStyleAttributeName:  [ps autorelease]
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

@implementation ModsVisualizer

- (NSString *)visualizerName {
    return @"Mods";
}

- (id)init {
    if (!(self = [super init]))
        return nil;

    NSRect windowFrame = { MODS_WIDTH, 100, 0, 100 };
    _visualizerWindow = [[NSWindow alloc]
         initWithContentRect:windowFrame
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [_visualizerWindow setLevel:NSScreenSaverWindowLevel];
    [_visualizerWindow setBackgroundColor:[NSColor clearColor]];
    [_visualizerWindow setMovableByWindowBackground:YES];
    [_visualizerWindow setFrameAutosaveName:@"mods visualizerFrame"];
    [_visualizerWindow setFrameUsingName:@"mods visualizerFrame" force:YES];
    [_visualizerWindow setOpaque:NO];

    _visualizerView = [[ModsVisualizerView alloc] init];
    [_visualizerWindow setContentView:_visualizerView];
    [_visualizerView noteFlagsChanged:0];

    return self;
}

- (void)dealloc  {
    [_visualizerWindow release];
    [_visualizerView release];
    [super dealloc];
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
    NSRect r = _visualizerWindow.frame;
    CGFloat right = r.origin.x + r.size.width;
    r.size.width = _visualizerView.frame.size.width;
    r.origin.x = right - r.size.width;
    [_visualizerWindow setFrame:r display:NO];
}

- (void)noteKeyEvent:(KCKeycastrEvent *)event {}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {}

+ (NSDictionary<NSString *,NSObject *> *)visualizerDefaults {
	return @{};
}

@end
