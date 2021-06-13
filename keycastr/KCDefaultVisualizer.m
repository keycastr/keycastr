//	Copyright (c) 2009 Stephen Deken
//	All rights reserved.
// 
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//	*	Redistributions of source code must retain the above copyright notice, this
//		list of conditions and the following disclaimer.
//	*	Redistributions in binary form must reproduce the above copyright notice,
//		this list of conditions and the following disclaimer in the documentation
//		and/or other materials provided with the distribution.
//	*	Neither the name KeyCastr nor the names of its contributors may be used to
//		endorse or promote products derived from this software without specific
//		prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import "KCDefaultVisualizer.h"
#import "NSBezierPath+RoundedRect.h"
#import "NSUserDefaults+Utility.h"


// TODO: seems this should be based on the font height, or shouldn't be needed at all
static const CGFloat kKCDefaultBezelHeight = 32.0;
static const CGFloat kKCDefaultBezelPadding = 10.0;


@implementation KCDefaultVisualizerFactory

-(NSString*) visualizerNibName
{
	return @"KCDefaultVisualizer";
}

-(Class) visualizerClass
{
	return [KCDefaultVisualizer class];
}

-(NSString*) visualizerName
{
	return @"Default";
}

@end

@implementation KCDefaultVisualizer

- (instancetype)init
{
    if (!(self = [super init]))
        return nil;

    visualizerWindow = [[KCDefaultVisualizerWindow alloc] init];

    return self;
}

- (void)dealloc
{
    [visualizerWindow release];
    [super dealloc];
}

-(NSString*) visualizerName
{
	return @"Default";
}

-(void) awakeFromNib
{
    [super awakeFromNib];
}

-(void) showVisualizer:(id)sender
{
	[visualizerWindow orderFront:self];
}

-(void) hideVisualizer:(id)sender
{
	[visualizerWindow orderOut:self];
}

-(void) deactivateVisualizer:(id)sender
{
	[visualizerWindow orderOut:self];
}

- (BOOL)shouldOnlyDisplayCommandKeys
{
    return [[[NSUserDefaults standardUserDefaults] valueForKey:@"default.commandKeysOnly"] boolValue];
}

- (void)noteKeyEvent:(KCKeystroke *)keystroke
{
    if (![keystroke isCommand] && [self shouldOnlyDisplayCommandKeys]) {
		return;
	}
	[visualizerWindow addKeystroke:keystroke];
}

@end

static NSRect KC_defaultFrame() {
    CGFloat width = NSWidth(NSScreen.mainScreen.frame) - 2 * kKCDefaultBezelPadding;
    return NSMakeRect(kKCDefaultBezelPadding, kKCDefaultBezelPadding, width, kKCDefaultBezelHeight);
}

@implementation KCDefaultVisualizerWindow {
	BOOL _shouldResize;
	BOOL _dragging;
}

- (instancetype)init
{
    return [self initWithContentRect:KC_defaultFrame()
                           styleMask:NSWindowStyleMaskBorderless
                             backing:NSBackingStoreBuffered
                               defer:NO];
}

- (instancetype)initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)styleMask backing:(NSBackingStoreType)backing defer:(BOOL)defer
{
    if (!(self = [super initWithContentRect:contentRect styleMask:styleMask backing:backing defer:defer]))
        return nil;
    
    _runningAnimations = [[NSMutableArray alloc] init];

    [self setFrameUsingName:@"KCBezelWindow default.bezelWindow" force:YES];
    [self setFrameAutosaveName:@"KCBezelWindow default.bezelWindow"];
    [self resizePreservingHeight:NO];
    
    CGFloat padding = 10;
    NSRect boundingRect = NSInsetRect([NSScreen mainScreen].frame, padding, padding);
    if (!NSPointInRect(self.frame.origin, boundingRect)) {
        NSLog(@"================> Out of range: %@", NSStringFromRect(self.frame));

        [self resetFrame];
    }
    
    [self setLevel:NSScreenSaverWindowLevel];
    [self setOpaque:NO];

    [self setBackgroundColor:[NSColor clearColor]];
    [self setAlphaValue:1];

    [self setMovableByWindowBackground:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillTerminate:)
                                                 name:NSApplicationWillTerminateNotification
                                               object:nil];
    return self;
}

- (void)dealloc {
    [_runningAnimations removeAllObjects];
    [_runningAnimations release];
    [super dealloc];
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [self _suspendAnimations];
    [self resizePreservingHeight:NO];
    [self saveFrameUsingName:self.frameAutosaveName];
}

- (void)resizePreservingHeight:(BOOL)keepHeight {
    NSLog(@"================> %@", NSStringFromSelector(_cmd));

    NSRect screenRect = self.screen ? self.screen.frame : NSScreen.mainScreen.frame;

    // Need to calculate a different width if our origin is dragged to a screen to the left
    CGFloat optimalWidth;
    if (NSMinX(self.frame) < NSMinX(self.screen.frame)) {
        optimalWidth = NSMinX(self.screen.frame) - NSMinX(self.frame) - kKCDefaultBezelPadding;
    } else {
        optimalWidth = fabs(NSMaxX(screenRect) - NSMinX(self.frame)) - kKCDefaultBezelPadding;
    }

    CGFloat height;
    if (keepHeight) {
        height = fmaxf(kKCDefaultBezelHeight, NSHeight(self.frame));
    } else {
        height = kKCDefaultBezelHeight;
    }

    NSRect frame = NSMakeRect(NSMinX(self.frame), NSMinY(self.frame), optimalWidth, height);
	[self setFrame:frame display:NO];
}

- (void)resetFrame {
    NSLog(@"================> %@", NSStringFromSelector(_cmd));

    [self setFrame:KC_defaultFrame() display:NO];
}

- (void)abandonCurrentBezelView {
    [_currentBezelView release];
	_currentBezelView = nil;
}

-(void) _cancelLineBreak
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(abandonCurrentBezelView) object:nil];
}

-(void) _scheduleLineBreak
{
	[self performSelector:@selector(abandonCurrentBezelView)
			   withObject:nil
			   afterDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"default.keystrokeDelay"]];
}

-(void) addKeystroke:(KCKeystroke*)keystroke
{
	[self _cancelLineBreak];
	NSString* charString = [keystroke convertToString];

    if ([keystroke isCommand])
	{
        [self abandonCurrentBezelView];
	}

	if (_currentBezelView == nil)
	{
        if (!(NSWidth(self.frame) > 0)) {
            NSLog(@"Fixing frame; width not greater than 0: %@", NSStringFromRect(self.frame));
            [self resetFrame];
        }

        NSColor *backgroundColor = [[NSUserDefaults standardUserDefaults] colorForKey:@"default.bezelColor"];
		_currentBezelView = [[KCDefaultVisualizerBezelView alloc]
			initWithMaxWidth:NSWidth(self.frame)
			text:charString
			backgroundColor:backgroundColor
			];
        [_currentBezelView setAutoresizingMask:NSViewMinYMargin];

        NSRect frame = self.frame;
        frame.size.height += 10 + _currentBezelView.frame.size.height;
		[self setFrame:frame display:YES animate:NO];

		[[self contentView] addSubview:_currentBezelView];
	}
	else
	{
		[_currentBezelView appendString:charString];
	}
    [self _scheduleLineBreak];
}

-(void) abandonCurrentView
{
	[self _cancelLineBreak];
}

-(void) addRunningAnimation:(KCBezelAnimation*)animation
{
    [_runningAnimations addObject:animation];
    [self saveFrameUsingName:self.frameAutosaveName];

    if (_dragging)
		[animation stopAnimation];
}

-(void) removeRunningAnimation:(KCBezelAnimation*)animation
{
	[_runningAnimations removeObject:animation];
    [self saveFrameUsingName:self.frameAutosaveName];

    if (_runningAnimations.count == 0) {
        if (_shouldResize) {
            _shouldResize = NO;
            [self resizePreservingHeight:YES];
        }
    }
}

- (void)_suspendAnimations
{
	NSUInteger vc = [_runningAnimations count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSAnimation* anim = [_runningAnimations objectAtIndex:i];
		[anim stopAnimation];
	}
}

- (void)_resumeAnimations
{
	NSUInteger vc = [_runningAnimations count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSAnimation* anim = [_runningAnimations objectAtIndex:i];
		[anim startAnimation];
	}
}

- (void)mouseDown:(NSEvent*)theEvent
{
    _dragging = YES;
    [self _suspendAnimations];

    [super mouseDown:theEvent];
}

- (void)mouseUp:(NSEvent*)theEvent
{
    _dragging = NO;
    _shouldResize = YES;
    [self _resumeAnimations];

    [super mouseUp:theEvent];
}

@end


@implementation KCBezelAnimation

-(KCBezelAnimation*) initWithBezelView:(KCDefaultVisualizerBezelView*)bezelView
{
	if (!(self = [super init]))
		return nil;

	_bezelView = [bezelView retain];

	return self;
}

- (void)dealloc {
    [_bezelView release];
    [super dealloc];
}

-(void) fadeOutOverDuration:(NSTimeInterval)duration
{
	if ([self isAnimating])
		return;

	if (duration < 0.01)
	{
		// just do it immediately
		[self animationDidEnd:self];
		return;
	}

	[self setDelegate:self];
	[self setDuration:duration];
	[self setFrameRate:30];
	[self setAnimationCurve:NSAnimationLinear];
	[self setAnimationBlockingMode:NSAnimationNonblocking];
	[self startAnimation];
}

-(void) setCurrentProgress:(NSAnimationProgress)progress
{
	[super setCurrentProgress:progress];

	[_bezelView setAlphaValue:(1 - progress)];
	[_bezelView setNeedsDisplay:YES];
}

-(void) animationDidEnd:(NSAnimation*)anim
{
	CGFloat deltaY = [_bezelView frame].size.height + 10;
	KCDefaultVisualizerWindow* w = (KCDefaultVisualizerWindow*)[_bezelView window];
	[w removeRunningAnimation:self];
	[_bezelView removeFromSuperview];

	NSArray* a = [[w contentView] subviews];
	NSUInteger vc = [a count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSView* v = [a objectAtIndex:i];
		NSRect r = [v frame];
		r.origin.y += deltaY;
		[v setFrame:r];
	}

	NSRect r = [w frame];
	r.size.height -= deltaY;
	if (r.size.height < 0)
		r.size.height = 0;
	[w setFrame:r display:YES animate:NO];
}

@end


@implementation KCDefaultVisualizerBezelView

static const int kKCBezelBorder = 6;

- (id)initWithMaxWidth:(CGFloat)maxWidth text:(NSString *)string backgroundColor:(NSColor *)color
{
	if (!(self = [super initWithFrame:NSMakeRect(0, 0, maxWidth, kKCDefaultBezelHeight)]))
		return nil;

	_opacity = 1.0;

	_maxWidth = maxWidth;
	_backgroundColor = [color retain];

	_textStorage = [[NSTextStorage alloc] initWithString:string];
	_textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(_maxWidth-kKCBezelBorder*2, FLT_MAX)];
	_layoutManager = [[NSLayoutManager alloc] init];
	[_layoutManager addTextContainer:_textContainer];
	[_textStorage addLayoutManager:_layoutManager];
	[_textStorage setAttributes:[self attributes] range:NSMakeRange(0, [_textStorage length])];

	[self setAutoresizingMask:NSViewMinYMargin];

	[self maybeResize];
	[self scheduleFadeOut];

	return self;
}

- (void)dealloc {
    [_backgroundColor release];
    [_textStorage release];
    [_textContainer release];
    [_layoutManager release];

    [super dealloc];
}

-(void) scheduleFadeOut
{
	NSTimeInterval fadeDelay = [[NSUserDefaults standardUserDefaults] floatForKey:@"default.fadeDelay"];
	if (fadeDelay == 0)
		fadeDelay = 2;
	SEL fadeOutSelector = @selector(beginFadeOut:);
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:fadeOutSelector object:nil];
	[self performSelector:fadeOutSelector withObject:nil afterDelay:fadeDelay];
}

-(void) beginFadeOut:(id)sender
{
	KCDefaultVisualizerWindow* w = (KCDefaultVisualizerWindow*)[self window];
	// [w abandonCurrentView];
	KCBezelAnimation* anim = [[KCBezelAnimation alloc] initWithBezelView:self];
	[anim fadeOutOverDuration:[[NSUserDefaults standardUserDefaults] floatForKey:@"default.fadeDuration"]];
	[w addRunningAnimation:[anim autorelease]];
}

-(NSDictionary*) attributes
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSColor* c = [ud colorForKey:@"default.textColor"];
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:[ud floatForKey:@"default.fontSize"]], NSFontAttributeName,
		[c colorWithAlphaComponent:_opacity * [c alphaComponent]], NSForegroundColorAttributeName,
		nil];
}

-(void) setAlphaValue:(float)opacity
{
	_opacity = opacity;
	[_textStorage setAttributes:[self attributes] range:NSMakeRange(0, [_textStorage length])];
}

-(void) drawRect:(NSRect)r
{
	NSRect frame = [self bounds];

	NSBezierPath *bgPath = [NSBezierPath bezierPath];
	[bgPath appendRoundedRect:frame radius:16];

	[[_backgroundColor colorWithAlphaComponent:_opacity * [_backgroundColor alphaComponent]] setFill];
	[bgPath fill];

	[_layoutManager drawGlyphsForGlyphRange:NSMakeRange(0,[_textStorage length]) atPoint:NSMakePoint(kKCBezelBorder, kKCBezelBorder)];
}

-(void) maybeResize
{
	NSRect frame = [self frame];
	[_layoutManager glyphRangeForTextContainer:_textContainer];
	NSSize size = [_layoutManager usedRectForTextContainer:_textContainer].size;
	size.width += kKCBezelBorder * 2;
	size.height += kKCBezelBorder * 2;
	if (frame.size.width != size.width || frame.size.height != size.height)
	{
		[self setFrameSize:size];
		if (size.height != frame.size.height)
		{
			float deltaY = size.height - frame.size.height;
			NSWindow* w = [self window];
			NSArray* a = [[w contentView] subviews];
			NSUInteger vc = [a count];
			int i;
			for (i = 0; i < vc; ++i)
			{
				NSView* v = [a objectAtIndex:i];
				if (v == self) continue;
				NSRect f = [v frame];
				if (f.origin.y > frame.origin.y)
					f.origin.y += deltaY;
			}
			NSRect r = [w frame];
			r.size.height += deltaY;
			[self setAutoresizingMask:NSViewMaxYMargin];
			[w setFrame:r display:YES];
			[self setAutoresizingMask:NSViewMinYMargin];
		}
	}
}

-(void) appendString:(NSString*)t
{
	[self scheduleFadeOut];
	[_textStorage appendAttributedString:[[[NSAttributedString alloc] initWithString:t] autorelease]];
	[_textStorage setAttributes:[self attributes] range:NSMakeRange(0, [_textStorage length])];
	[self maybeResize];
	[self setNeedsDisplay:YES];
}

-(BOOL) isFlipped
{
	return YES;
}

@end
