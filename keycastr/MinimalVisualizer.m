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

#import "MinimalVisualizer.h"
#import "NSBezierPath+RoundedRect.h"
#import "KCKeystroke.h"
#import "KCMouseEvent.h"
#import "NSUserDefaults+Utility.h"

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
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    NSRect frame = self.frame;
    NSRect bgFrame = self.frame;

    CGFloat x = frame.size.width, y;
    NSSize size;

    [[NSColor clearColor] setFill];
    NSRectFill(frame);
    
    // Prevent drawing empty bezel
    if (!_flags && !_characters) return;

    if (bgFrame.size.width > 0) {
        [[ud colorForKey:@"minimal.bezelColor"] setFill];
        NSBezierPath* bp = [NSBezierPath bezierPath];
        [bp appendRoundedRect:bgFrame radius:[ud floatForKey:@"minimal.borderRadius"]];
        [bp fill];
    }

    NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle alloc] init];
    [ps setAlignment:NSTextAlignmentCenter];

    NSShadow* shadow = [[NSShadow alloc] init];
    [shadow setShadowColor:[ud colorForKey:@"minimal.textShadowColor"]];
    [shadow setShadowBlurRadius:2];
    [shadow setShadowOffset:NSMakeSize(2,-2)];

    NSDictionary* attr = @{
        NSFontAttributeName:            [NSFont boldSystemFontOfSize:[ud floatForKey:@"minimal.fontSize"]],
        NSForegroundColorAttributeName: [ud colorForKey:@"minimal.textColor"],
        NSShadowAttributeName:          shadow,
        NSParagraphStyleAttributeName:  ps
    };

    CGFloat width = [ud integerForKey:@"minimal.bezelSize"];

    if (_characters) {
        size = [_characters sizeWithAttributes:attr];
        y = (frame.size.height - size.height) / 2.0;
        x -= width;
        [_characters drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
    }

	if (_flags & NSEventModifierFlagCommand) {
		NSString* commandKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x98\x01"];
		size = [commandKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= width;
		[commandKeyString drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
	}

	if (_flags & NSEventModifierFlagShift) {
		NSString* shiftKeyString = [NSString stringWithUTF8String:"\xe2\x87\xa7\x01"];
		size = [shiftKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= width;
		[shiftKeyString drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
	}

    if (_flags & NSEventModifierFlagOption) {
        NSString* altKeyString = [NSString stringWithUTF8String:"\xe2\x8c\xa5\x01"];
        size = [altKeyString sizeWithAttributes:attr];
        y = (frame.size.height - size.height) / 2.0;
        x -= width;
        [altKeyString drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
    }

	if (_flags & NSEventModifierFlagControl) {
		NSString* controlKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x83\x01"];
		size = [controlKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= width;
		[controlKeyString drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
	}

	if (_flags & NSEventModifierFlagFunction) {
		NSString* controlKeyString = [NSString stringWithUTF8String:"fn"];
		size = [controlKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= width;
		[controlKeyString drawInRect:NSMakeRect(x, y, width, size.height) withAttributes:attr];
	}
}

- (void)noteFlagsChanged:(uint32_t)flags {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    // Remove flags that shouldn't be shown
    if (![ud boolForKey:@"minimal.display.command"]) {
        flags &= ~NSEventModifierFlagCommand;
    }
    if (![ud boolForKey:@"minimal.display.shift"]) {
        flags &= ~NSEventModifierFlagShift;
    }
    if (![ud boolForKey:@"minimal.display.option"]) {
        flags &= ~NSEventModifierFlagOption;
    }
    if (![ud boolForKey:@"minimal.display.control"]) {
        flags &= ~NSEventModifierFlagControl;
    }
    if (![ud boolForKey:@"minimal.display.function"]) {
        flags &= ~NSEventModifierFlagFunction;
    }
    
    _flags = flags;
    
    [self adjustFrameSize];
}

- (void)noteCharactersChanged:(NSString *)characters {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    if (!characters || [ud boolForKey:@"minimal.display.nonmodifier"]) {
        _characters = characters;
    }
    
    [self adjustFrameSize];
}

- (void)noteMouseChanged:(BOOL)pressed {
    _mouse = pressed;
    
    [self adjustFrameSize];
}

- (void)adjustFrameSize {    
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
    NSString *trimmed = [_characters stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    // Get length of characters (counting emojis as 1 character)
    __block NSUInteger charactersCount = 0;
    [trimmed enumerateSubstringsInRange:NSMakeRange(0, trimmed.length)
                                options:NSStringEnumerationByComposedCharacterSequences
                             usingBlock:^(NSString *s, NSRange r, NSRange e, BOOL *stop) { charactersCount++; }];
    
    CGFloat bezelSize = [ud integerForKey:@"minimal.bezelSize"];
    CGFloat width = round(bezelSize * (CGFloat)(
        [self flagsCount] + charactersCount + ([self mouseEnabled] ? _mouse : 0)
    ));
    
    NSRect windowFrame = self.window.frame;
    
    NSRect newFrame = windowFrame;
    newFrame.size.width = width;
    newFrame.size.height = bezelSize;
    
    if ([ud boolForKey:@"minimal.anchorRight"]) {
        newFrame.origin.x = round(NSMaxX(windowFrame)) - width;
    }
    
    [self.window setFrame:newFrame display:YES animate:NO];
    
    [self setFrame:NSMakeRect(0, 0, width, bezelSize)];
    [self setNeedsDisplay:YES];
}

@end

@implementation MinimalVisualizer

@dynamic preferencesView;

- (NSString *)visualizerName {
    return @"Minimal";
}

- (id)init {
    if (!(self = [super init]))
        return nil;

    // autosave frame was not working, despite best efforts. Easy workaround to use defaults instead.
    // (and autosave frame _uses_ defaults anyway so same thing in the end?)
    // TODO(AK): It appears we sometimes retrieve a stale frame this way with a non-0 width, which was probably stored the last time the app exited via CMD-Q
    // This strategy also makes it more complicated to adjust the visualizer's dimension later, so we still need to revisit this.
    CGFloat bezelSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"minimal.bezelSize"];
    NSString *frameValue = [[NSUserDefaults standardUserDefaults] stringForKey:@"minimal.savedFrame"];
    NSRect windowFrame = { bezelSize, bezelSize, 0, bezelSize };
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
    [self charactersDidChange];
}

- (void)charactersDidChange {
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

- (void)noteKeyEvent:(KCKeystroke *)keystroke {
    if (keystroke.underlyingEvent.isARepeat) {
        return;
    }

    NSString *characters = keystroke.isCommand ? [keystroke.charactersIgnoringModifiers uppercaseString] : keystroke.charactersIgnoringModifiers;
    // TODO: special characters
    [_visualizerView noteCharactersChanged:characters];
    [self charactersDidChange];
}

- (void)noteKeyUpEvent:(KCKeycastrEvent *)event {
    [_visualizerView noteCharactersChanged:nil];
    [self charactersDidChange];
}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {}

+ (NSDictionary<NSString *,NSObject *> *)visualizerDefaults {
    return @{
        @"minimal.display.command": @YES,
        @"minimal.display.option": @YES,
        @"minimal.display.control": @YES,
        @"minimal.display.shift": @YES,
        @"minimal.display.function": @YES,
        @"minimal.display.nonmodifier": @YES,
        @"minimal.anchorRight": @NO,
        @"minimal.fontSize": @80.0,
        @"minimal.bezelSize": @100.0,
        @"minimal.borderRadius": @10.0,
        @"minimal.bezelColor": [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0 alpha:0.75]
                                                   requiringSecureCoding:NO
                                                                   error:NULL],
        @"minimal.textColor": [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1 alpha:8]
                                                  requiringSecureCoding:NO
                                                                  error:NULL],
        @"minimal.textShadowColor": [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]
                                                          requiringSecureCoding:NO
                                                                          error:NULL],
    };
}

@end
