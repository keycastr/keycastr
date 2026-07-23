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
#import "KCEventTransformer.h"
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

    [[NSColor clearColor] setFill];
    NSRectFill(frame);

    // Prevent drawing empty bezel
    if (!_flags && !_characters && !_mouse) return;

    if (frame.size.width > 0) {
        [[ud colorForKey:@"minimal.bezelColor"] setFill];
        NSBezierPath* bp = [NSBezierPath bezierPath];
        [bp appendRoundedRect:frame radius:[ud floatForKey:@"minimal.borderRadius"]];
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

    // Glyphs occupy fixed-width slots laid out right-to-left: mouse, characters,
    // then modifiers in ⌘⇧⌥⌃fn order.
    CGFloat slotWidth = [ud integerForKey:@"minimal.bezelSize"];
    __block CGFloat x = frame.size.width;
    void (^drawGlyph)(NSString *) = ^(NSString *glyph) {
        NSSize size = [glyph sizeWithAttributes:attr];
        CGFloat y = (frame.size.height - size.height) / 2.0;
        x -= slotWidth;
        [glyph drawInRect:NSMakeRect(x, y, slotWidth, size.height) withAttributes:attr];
    };

    if (_mouse) {
        drawGlyph(@"🖱️");
    }
    if (_characters) {
        drawGlyph(_characters);
    }
    if (_flags & NSEventModifierFlagCommand) {
        drawGlyph([NSString stringWithUTF8String:"\xe2\x8c\x98\x01"]);
    }
    if (_flags & NSEventModifierFlagShift) {
        drawGlyph([NSString stringWithUTF8String:"\xe2\x87\xa7\x01"]);
    }
    if (_flags & NSEventModifierFlagOption) {
        drawGlyph([NSString stringWithUTF8String:"\xe2\x8c\xa5\x01"]);
    }
    if (_flags & NSEventModifierFlagControl) {
        drawGlyph([NSString stringWithUTF8String:"\xe2\x8c\x83\x01"]);
    }
    if (_flags & NSEventModifierFlagFunction) {
        drawGlyph(@"fn");
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
    
    // -drawRect: renders the whole _characters string within a single bezel slot,
    // so it always occupies exactly one slot regardless of length. Counting each
    // composed character here over-sized the frame for multi-character key labels
    // (e.g. "F1", "F10"), leaving a trailing empty bezel box.
    BOOL hasCharacters = [_characters stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]].length > 0;
    
    CGFloat bezelSize = [ud integerForKey:@"minimal.bezelSize"];
    CGFloat width = round(bezelSize * (CGFloat)(
        [self flagsCount] + (hasCharacters ? 1 : 0) + _mouse
    ));
    
    // Size the view to its content only. The owning MinimalVisualizer is the sole
    // owner of the window frame (position + anchoring); see -charactersDidChange.
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

    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    CGFloat bezelSize = [ud integerForKey:@"minimal.bezelSize"];

    _visualizerWindow = [[NSWindow alloc]
         initWithContentRect:NSMakeRect(bezelSize, bezelSize, 0, bezelSize)
        styleMask:NSWindowStyleMaskBorderless
        backing:NSBackingStoreBuffered
        defer:NO];
    [_visualizerWindow setLevel:NSScreenSaverWindowLevel];
    [_visualizerWindow setBackgroundColor:[NSColor clearColor]];
    [_visualizerWindow setMovableByWindowBackground:YES];
    [_visualizerWindow setOpaque:NO];
    [_visualizerWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [_visualizerWindow setTitle:@"Minimal Visualizer"];

    _visualizerView = [[MinimalVisualizerView alloc] init];
    [_visualizerView noteFlagsChanged:0];
    [_visualizerWindow setContentView:_visualizerView];

    [_visualizerWindow setFrameAutosaveName:@"MinimalVisualizerWindow"];
    [_visualizerWindow setFrameUsingName:@"MinimalVisualizerWindow"];

    // AppKit doesn't keep borderless windows on-screen; guard against a frame saved
    // on a display that's since been disconnected.
    NSRect frame = _visualizerWindow.frame;
    NSRect visible = (_visualizerWindow.screen ?: NSScreen.mainScreen).visibleFrame;
    frame.origin.x = MAX(NSMinX(visible), MIN(frame.origin.x, NSMaxX(visible) - frame.size.width));
    frame.origin.y = MAX(NSMinY(visible), MIN(frame.origin.y, NSMaxY(visible) - frame.size.height));
    [_visualizerWindow setFrame:frame display:NO];

    _anchorRight = [self effectiveAnchorRight];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:ud];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

// YES pins the right edge (content grows leftward); NO pins the left edge.
- (BOOL)effectiveAnchorRight {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"minimal.anchorRight"];
}

- (void)charactersDidChange {
    NSRect windowFrame = _visualizerWindow.frame;
    NSSize contentSize = _visualizerView.frame.size;

    if ([self effectiveAnchorRight]) {
        // Right edge fixed; grows/shrinks leftward.
        CGFloat right = NSMaxX(windowFrame);
        windowFrame.size = contentSize;
        windowFrame.origin.x = right - contentSize.width;
    } else {
        // Left edge fixed; grows/shrinks rightward.
        windowFrame.size = contentSize;
    }

    [_visualizerWindow setFrame:windowFrame display:NO];
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    // Fires for every defaults write (including AppKit's frame autosave); act only
    // when the anchor preference actually flips.
    BOOL anchorRight = [self effectiveAnchorRight];
    if (anchorRight == _anchorRight) {
        return;
    }
    _anchorRight = anchorRight;

    // Re-anchor now rather than waiting for the next keystroke.
    [self charactersDidChange];
}

- (void)noteKeyEvent:(KCKeystroke *)keystroke {
    if (keystroke.underlyingEvent.isARepeat) {
        return;
    }

    NSString *specialKey = [KCEventTransformer.specialKeys objectForKey:@(keystroke.keyCode)];
    if (specialKey) {
        [_visualizerView noteCharactersChanged:specialKey];
    } else {
        NSString *characters;
        if (keystroke.isCommand) {
            if (keystroke.characters.length) {
                characters = [keystroke.characters uppercaseString];
            } else {
                characters = [keystroke.charactersIgnoringModifiers uppercaseString];
            }
        } else {
            characters = keystroke.charactersIgnoringModifiers;
        }
        [_visualizerView noteCharactersChanged:characters];
    }
    [self charactersDidChange];
}

- (void)noteKeyUpEvent:(KCKeycastrEvent *)event {
    [_visualizerView noteCharactersChanged:nil];
    [self charactersDidChange];
}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent {
    if (NSEventMaskFromType(mouseEvent.type) & (NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown | NSEventMaskOtherMouseDown)) {
        [_visualizerView noteMouseChanged:YES];
    }
    else if (NSEventMaskFromType(mouseEvent.type) & (NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp)) {
        [_visualizerView noteMouseChanged:NO];
    }
    
    [self charactersDidChange];
}

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
        @"minimal.textColor": [NSKeyedArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1 alpha:0.8]
                                                  requiringSecureCoding:NO
                                                                  error:NULL],
        @"minimal.textShadowColor": [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]
                                                          requiringSecureCoding:NO
                                                                          error:NULL],
    };
}

@end
