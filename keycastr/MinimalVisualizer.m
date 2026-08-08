//  Copyright (c) 2023 Colin Gray
//  Copyright (c) 2026 Daniel Costa
//  Copyright (c) 2026 Andrew Kitchen
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

// Largest font point size, as a fraction of the bezel height, that still fits
// within the bezel (rendered text height is ~1.16x the point size). Font and
// bezel size are coupled to hold this bound so text never overruns the bezel.
// See -enforceFontBezelCoupling.
static CGFloat const kMinimalMaxFontToBezelRatio = 0.85;

// Window position is persisted as the x-coordinate of the anchored edge (the
// right edge when anchored right, otherwise the left edge) plus the vertical
// origin. Storing the anchored edge -- rather than the whole frame -- keeps
// restore correct no matter how much content was showing when the value was
// saved. AppKit's frame autosave stored a full frame instead, which restored the
// wrong position after a ⌘Q that quit the app while glyphs were on screen.
static NSString *const kMinimalAnchorXKey = @"minimal.anchorX";
static NSString *const kMinimalOriginYKey = @"minimal.originY";

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

- (void)noteFlagsChanged:(NSEventModifierFlags)flags {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    // ⌘⇧⌥⌃ always render while held (the Minimal visualizer's live-HUD identity);
    // only the fn/globe badge is optional.
    if (![ud boolForKey:@"minimal.display.includeFunctionKey"]) {
        flags &= ~NSEventModifierFlagFunction;
    }

    _flags = flags;

    [self adjustFrameSize];
}

- (void)noteCharactersChanged:(NSString *)characters {
    // Whether a key is worth showing is decided by the owning MinimalVisualizer
    // (see -shouldDisplayKeystroke:); the view just renders what it's handed.
    _characters = characters;

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

    _anchorRight = [self effectiveAnchorRight];
    [self restoreWindowPosition];

    // Seed the size caches and correct any pre-existing config that violates the
    // font/bezel fit constraint (see -enforceFontBezelCoupling).
    [self enforceFontBezelCoupling];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange:)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:ud];

    // Persist the anchored edge whenever the user drags the window (and, harmlessly,
    // whenever we re-anchor it ourselves); see -saveWindowPosition.
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidMove:)
                                                 name:NSWindowDidMoveNotification
                                               object:_visualizerWindow];

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

- (void)noteFlagsChanged:(NSEventModifierFlags)flags {
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

// Places the (empty, zero-width) window so its anchored edge sits at the saved
// position; the first event then grows it from that edge. The anchored edge is
// invariant to content width, so this restores correctly even when the saved
// value was captured with glyphs on screen (e.g. a ⌘Q that quit the app).
- (void)restoreWindowPosition {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    CGFloat bezelSize = [ud integerForKey:@"minimal.bezelSize"];

    NSRect frame = NSMakeRect([ud doubleForKey:kMinimalAnchorXKey],
                              [ud doubleForKey:kMinimalOriginYKey],
                              0, bezelSize);

    // First run has no saved position; fall back to the window's original spot.
    if ([ud objectForKey:kMinimalAnchorXKey] == nil) {
        frame.origin = NSMakePoint(bezelSize, bezelSize);
    }

    // AppKit doesn't keep borderless windows on-screen; guard against a position
    // saved on a display that's since been disconnected.
    NSRect visible = (_visualizerWindow.screen ?: NSScreen.mainScreen).visibleFrame;
    frame.origin.x = MAX(NSMinX(visible), MIN(frame.origin.x, NSMaxX(visible) - frame.size.width));
    frame.origin.y = MAX(NSMinY(visible), MIN(frame.origin.y, NSMaxY(visible) - frame.size.height));
    [_visualizerWindow setFrame:frame display:NO];
}

- (void)saveWindowPosition {
    NSRect frame = _visualizerWindow.frame;
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    [ud setDouble:([self effectiveAnchorRight] ? NSMaxX(frame) : NSMinX(frame))
           forKey:kMinimalAnchorXKey];
    [ud setDouble:NSMinY(frame) forKey:kMinimalOriginYKey];
}

- (void)windowDidMove:(NSNotification *)notification {
    [self saveWindowPosition];
}

// Writes a coupled size through the shared NSUserDefaultsController rather than
// NSUserDefaults directly, so the slider bound to this key in Preferences updates
// live; a plain defaults write leaves the existing Cocoa binding stale.
- (void)setCoupledSizeDefault:(NSString *)key toDouble:(CGFloat)value {
    NSString *keyPath = [@"values." stringByAppendingString:key];
    [[NSUserDefaultsController sharedUserDefaultsController] setValue:@(value) forKeyPath:keyPath];
}

// Holds font point size within kMinimalMaxFontToBezelRatio of the bezel height so
// text never overruns the bezel. Font and bezel stay independent until a change
// crosses the boundary, then the slider the user *didn't* move yields: growing the
// font past the bound grows the bezel to fit; shrinking the bezel past the bound
// shrinks the font to fit. The _adjustingCoupledSizes guard swallows the
// re-entrant notification from writing the counterpart preference.
- (void)enforceFontBezelCoupling {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    CGFloat font = [ud floatForKey:@"minimal.fontSize"];
    CGFloat bezel = [ud floatForKey:@"minimal.bezelSize"];

    BOOL fontChanged = (font != _fontSize);
    BOOL bezelChanged = (bezel != _bezelSize);
    if (!fontChanged && !bezelChanged) {
        return;
    }

    CGFloat maxFont = kMinimalMaxFontToBezelRatio * bezel;
    if (font > maxFont) {
        _adjustingCoupledSizes = YES;
        if (fontChanged && !bezelChanged) {
            bezel = ceil(font / kMinimalMaxFontToBezelRatio);
            [self setCoupledSizeDefault:@"minimal.bezelSize" toDouble:bezel];
        } else {
            font = floor(maxFont);
            [self setCoupledSizeDefault:@"minimal.fontSize" toDouble:font];
        }
        _adjustingCoupledSizes = NO;
    }

    _fontSize = font;
    _bezelSize = bezel;
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    // Fires for every defaults write (including AppKit's frame autosave and our own
    // coupled-size writes); ignore the writes we make from within this handler.
    if (_adjustingCoupledSizes) {
        return;
    }

    [self enforceFontBezelCoupling];

    // Act on the anchor only when the preference actually flips.
    BOOL anchorRight = [self effectiveAnchorRight];
    if (anchorRight == _anchorRight) {
        return;
    }
    _anchorRight = anchorRight;

    // Re-anchor now rather than waiting for the next keystroke.
    [self charactersDidChange];
}

// Decides whether a keystroke's base key label should be displayed. Modifier
// glyphs are handled separately (always shown) via -noteFlagsChanged:; this
// governs only the non-modifier key label.
//
// Each keystroke is classified into exactly one category by precedence, and the
// matching checklist toggle decides visibility:
//   holds ⌘/⌃  -> Command keys              (⌘C, ⌃Space, ⌘←)
//   else ⌥     -> Modified keys             (⌥E, ⌥⇧E, ⌥←)
//   else special -> Special & navigation keys (←, Tab, F5, ⇧Tab)
//   else       -> All keys                  (a, A, 7, !)
- (BOOL)shouldDisplayKeystroke:(KCKeystroke *)keystroke {
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

    if (keystroke.isCommand) {
        return [ud boolForKey:@"minimal.display.commandKeys"];
    }

    // Command/Control are handled above. Only Option marks a keystroke as modified;
    // Shift-only keystrokes fall through so capitals and shifted punctuation count
    // as ordinary typing (or special keys), matching how people read them.
    if (keystroke.modifierFlags & NSEventModifierFlagOption) {
        return [ud boolForKey:@"minimal.display.modifiedKeys"];
    }

    if ([KCEventTransformer.specialKeys objectForKey:@(keystroke.keyCode)] != nil) {
        return [ud boolForKey:@"minimal.display.specialKeys"];
    }

    return [ud boolForKey:@"minimal.display.allKeys"];
}

- (void)noteKeyEvent:(KCKeystroke *)keystroke {
    if (keystroke.underlyingEvent.isARepeat) {
        return;
    }

    NSString *characters = nil;
    if ([self shouldDisplayKeystroke:keystroke]) {
        characters = [[KCEventTransformer currentTransformer] keyCapForKeystroke:keystroke];
    }
    [_visualizerView noteCharactersChanged:characters];
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
        // ⌘⇧⌥⌃ glyphs always render; the checklist below governs base-key labels
        // (and the optional fn badge). A keystroke is classified into exactly one
        // category by precedence (see -shouldDisplayKeystroke:); default all-on
        // shows everything.
        @"minimal.display.commandKeys": @YES,
        @"minimal.display.modifiedKeys": @YES,
        @"minimal.display.specialKeys": @YES,
        @"minimal.display.allKeys": @YES,
        @"minimal.display.includeFunctionKey": @YES,
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
