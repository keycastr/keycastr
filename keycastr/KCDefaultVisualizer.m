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

@interface KCDefaultVisualizer (Private)

-(void) _createVisualizerWindow;

@end

@implementation KCDefaultVisualizer

-(id) init
{
	if (!(self = [super init]))
		return nil;

	return self;
}

- (void)dealloc {
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

-(void) _createVisualizerWindow
{
	if (visualizerWindow == nil)
	{
        NSRect screenFrame = [NSScreen mainScreen].frame;
		NSRect frameRect = NSMakeRect(0, 100, NSWidth(screenFrame), 100);
		visualizerWindow = [[KCDefaultVisualizerWindow alloc]
			initWithContentRect:frameRect
			styleMask:NSBorderlessWindowMask
			backing:NSBackingStoreBuffered
			defer:NO];
	}
}

-(void) showVisualizer:(id)sender
{
	[self _createVisualizerWindow];
	[visualizerWindow orderFront:self];
}

-(void) hideVisualizer:(id)sender
{
	[self _createVisualizerWindow];
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

- (void)noteKeyEvent:(KCKeystroke*)keystroke
{
    if (![keystroke isCommand] && [self shouldOnlyDisplayCommandKeys]) {
		return;
	}
	[visualizerWindow addKeystroke:keystroke];
}

@end

@implementation KCDefaultVisualizerWindow

-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSWindowStyleMask)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
    if (!(self = [super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag]))
        return nil;
    
    _runningAnimations = [[NSMutableArray alloc] init];
    
    [self setFrameUsingName:@"KCBezelWindow default.bezelWindow"];
    [self setFrameAutosaveName:@"KCBezelWindow default.bezelWindow"];
    
    CGFloat padding = 10;
    NSRect boundingRect = NSInsetRect([NSScreen mainScreen].frame, padding, padding);
    if (!NSPointInRect(self.frame.origin, boundingRect)) {
        [self resetFrame];
    }
    
    [self setLevel:NSScreenSaverWindowLevel];
    [self setOpaque:NO];
    [self setBackgroundColor:[NSColor clearColor]];
    
    [self setAlphaValue:1];
    [self setMovableByWindowBackground:YES];
    [self setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(screenParametersDidChange)
                                                 name:NSApplicationDidChangeScreenParametersNotification
                                               object:nil];
    
    return self;
}

- (void)dealloc {
    [_runningAnimations removeAllObjects];
    [_runningAnimations release];
    [super dealloc];
}

- (void)screenParametersDidChange {
    [self resetFrame];
}

- (void)resetFrame {
    CGFloat padding = 10;
    NSRect defaultFrame = NSMakeRect(padding, padding, self.frame.size.width, self.frame.size.height);
    [self setFrame:defaultFrame display:NO];
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
//		NSLog( @"%d", [keystroke isCommand] );
	if ([keystroke isCommand])
	{
        [self abandonCurrentBezelView];
	}

	if (_currentBezelView == nil)
	{
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSRect frame = [self frame];

        CGFloat maxWidth = frame.size.width;
        if (!(maxWidth > 0)) {
            NSLog(@"Fixing frame; width not greater than 0: %@", NSStringFromRect(frame));
            maxWidth = 200;
            frame.size = NSMakeSize(maxWidth, fmaxf(32.0, frame.size.height));
            [self setFrame:frame display:YES];
            NSLog(@"New frame: %@", NSStringFromRect(frame));
        }
		_currentBezelView = [[KCDefaultVisualizerBezelView alloc]
			initWithMaxWidth:maxWidth
			text:charString
			backgroundColor:[userDefaults colorForKey:@"default.bezelColor"]
			];
		frame.size.height += 10 + _currentBezelView.frame.size.height;
		[_currentBezelView setAutoresizingMask:NSViewMinYMargin];
		
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
	if (_dragging)
		[animation stopAnimation];
}

-(void) removeRunningAnimation:(KCBezelAnimation*)animation
{
	[_runningAnimations removeObject:animation];
}

-(void) _suspendAnimations
{
	NSUInteger vc = [_runningAnimations count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSAnimation* anim = [_runningAnimations objectAtIndex:i];
		[anim stopAnimation];
	}
}

-(void) _resumeAnimations
{
	NSUInteger vc = [_runningAnimations count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSAnimation* anim = [_runningAnimations objectAtIndex:i];
		[anim startAnimation];
	}
}

-(void) mouseDown:(NSEvent*)theEvent
{
	_dragging = YES;
	[self _suspendAnimations];
	[super mouseDown:theEvent];
}

-(void) mouseUp:(NSEvent*)theEvent
{
	[super mouseUp:theEvent];
	[self _resumeAnimations];
	_dragging = NO;
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

//	NSLog( @"%f", progress );

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

-(id) initWithMaxWidth:(CGFloat)maxWidth text:(NSString *)string backgroundColor:(NSColor *)color
{
	if (!(self = [super initWithFrame:NSMakeRect(0,0,maxWidth,32)]))
	{
		return nil;
	}

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

-(NSShadow*) shadow
{
	NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor colorWithCalibratedWhite:0 alpha:_opacity]];
	[shadow setShadowBlurRadius:2];
	[shadow setShadowOffset:NSMakeSize(0,-1)];
	return shadow;
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

	[[self shadow] set];
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

/*
@implementation KCDefaultVisualizerKeystrokeView

-(id) initWithFrame:(NSRect)frame
{
	// always, always start with a zero-height frame
	frame.size.height = 0;
    if (![super initWithFrame:frame])
		return nil;

	_actualHeight = 0;
	_sticky = NO;

	_buf = [[NSTextStorage alloc] initWithString:@""];
	NSTextContainer *textContainer = [[NSTextContainer alloc] initWithContainerSize:NSMakeSize(frame.size.width, FLT_MAX)];
	NSLayoutManager *layoutManager = [[NSLayoutManager alloc] init];
	[layoutManager addTextContainer:textContainer];
	[_buf addLayoutManager:layoutManager];
	[layoutManager release];
	[textContainer release];
	[_buf setAttributes:[self attributes] range:NSMakeRange(0, [_buf length])];

    return self;
}

-(void) dealloc
{
	if (_buf)
	{
		[_buf release];
		_buf = nil;
	}
	[super dealloc];
}

-(BOOL) isFlipped
{
	return YES;
}

-(NSShadow*) sharedShadow
{
	static NSShadow* shadow = nil;
	if (shadow == nil)
	{
		shadow = [[NSShadow alloc] init];
		[shadow setShadowColor:[NSColor blackColor]];
		[shadow setShadowBlurRadius:2];
		[shadow setShadowOffset:NSMakeSize(0,-1)];
	}
	return shadow;
}

-(NSDictionary*) attributes
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	return [NSDictionary dictionaryWithObjectsAndKeys:
		[NSFont systemFontOfSize:[ud floatForKey:@"default.fontSize"]], NSFontAttributeName,
		[ud colorForKey:@"default.textColor"], NSForegroundColorAttributeName,
		nil];
}

-(void) drawRect:(NSRect)rect
{
	[_buf setAttributes:[self attributes] range:NSMakeRange(0, [_buf length])];
	[[self sharedShadow] set];
	NSLayoutManager *lm = [[_buf layoutManagers] objectAtIndex:0];
	[lm drawGlyphsForGlyphRange:NSMakeRange(0,[_buf length]) atPoint:NSZeroPoint];
}

-(float) heightForString
{
	NSLayoutManager *lm = [[_buf layoutManagers] objectAtIndex:0];
	NSTextContainer *tc = [[lm textContainers] objectAtIndex:0];
	[lm glyphRangeForTextContainer:tc];
	return [lm usedRectForTextContainer:tc].size.height;
}

-(void) resize
{
	float h = [self heightForString];
	if (h != _actualHeight)
	{
		// kick off an animation
		_actualHeight = h;
		// [(KCBezelView*)[self superview] animateKeystrokeView:self toHeight:h];
	}
}

-(void) appendString:(NSString*)str
{
	if (!_sticky)
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(fadeOut:) object:nil];
	NSAttributedString *s = [[NSAttributedString alloc] initWithString:str];
	[_buf appendAttributedString:s];
	[s release];
	[_buf setAttributes:[self attributes] range:NSMakeRange(0, [_buf length])];
	[self resize];
	[self setNeedsDisplay:YES];
	if (!_sticky)
		[self performSelector:@selector(fadeOut:) withObject:nil afterDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"fadeDelay"]];
}


@end
*/
