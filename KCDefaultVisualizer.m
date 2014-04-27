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

#import "KCKeystrokeTransformer.h"

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
	if (![super init])
		return nil;

	return self;
}

-(NSString*) visualizerName
{
	return @"Default";
}

-(void) awakeFromNib
{
}

-(void) _createVisualizerWindow
{
	if (visualizerWindow == nil)
	{
		NSRect frameRect = NSMakeRect(0,100,200,100);
		visualizerWindow = [[[KCDefaultVisualizerWindow alloc]
			initWithContentRect:frameRect
			styleMask:NSBorderlessWindowMask
			backing:NSBackingStoreBuffered
			defer:NO
			] retain];
		[visualizerWindow orderFront:self];
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

-(void) noteKeyEvent:(KCKeystroke*)keystroke
{
	if (![keystroke isCommand] && [[[NSUserDefaults standardUserDefaults] valueForKey:@"default.commandKeysOnly"] boolValue])
	{
		// This is not a command key, and we want to only display command keys, so we ignore this.
		return;
	}
	[visualizerWindow addKeystroke:keystroke];
}

@end

@interface SSS : NSView
{
}
@end

@implementation SSS

-(BOOL) isFlipped
{
	return YES;
}

@end

@implementation KCDefaultVisualizerWindow

-(id) initWithContentRect:(NSRect)contentRect styleMask:(NSUInteger)aStyle backing:(NSBackingStoreType)bufferingType defer:(BOOL)flag
{
	if (![super initWithContentRect:contentRect styleMask:aStyle backing:bufferingType defer:flag])
		return nil;

	_bezelViews = [[NSMutableArray alloc] init];
	_runningAnimations = [[NSMutableArray alloc] init];

	NSScreen *screen = [NSScreen mainScreen];
	NSRect screenFrame = [screen frame];

	NSRect frame = NSMakeRect(screenFrame.size.width-210, 10, contentRect.size.width, contentRect.size.height);

	[self setFrame:frame display:NO];
	[self setFrameUsingName:@"KCBezelWindow default.bezelWindow"];
	[self setFrameAutosaveName:@"KCBezelWindow default.bezelWindow"];

	[self setLevel:NSScreenSaverWindowLevel];
	[self setOpaque:NO];
	[self setBackgroundColor:[NSColor clearColor]];
	
	[self setAlphaValue:1];
	[self setMovableByWindowBackground:YES];

/*
	NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
	NSView* vv = [[KCDefaultVisualizerBezelView alloc]
		initWithMaxWidth:r.size.width
		text:@"Welcome to KeyCastr, you sucker!"
		isCommand:NO
		fontSize:[userDefaults floatForKey:@"default.fontSize"]
		fontColor:[userDefaults colorForKey:@"default.textColor"]
		backgroundColor:[userDefaults colorForKey:@"default.bezelColor"]
		];
	[[self contentView] addSubview:vv];
*/

	return self;
}

-(void) _lineBreak:(id)sender
{
	_mostRecentBezelView = nil;
}

-(void) _cancelLineBreak
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_lineBreak:) object:nil];
}

-(void) _scheduleLineBreak
{
	[self performSelector:@selector(_lineBreak:) withObject:nil afterDelay:[[NSUserDefaults standardUserDefaults] floatForKey:@"default.keystrokeDelay"]];
}

-(void) addKeystroke:(KCKeystroke*)keystroke
{
	[self _cancelLineBreak];
	NSString* charString = [keystroke convertToString];
//		NSLog( @"%d", [keystroke isCommand] );
	if (_mostRecentBezelView == nil || [keystroke isCommand])
	{
		NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
        NSRect frame = [self frame];
        CGFloat maxWidth = frame.size.width;
        if (!(maxWidth > 0)) {
            NSLog(@"Fixing frame; width not greater than 0: %@", NSStringFromRect(frame));
            maxWidth = 200;
            frame.size = NSMakeSize(maxWidth, MAX(32.0, frame.size.height));
            [self setFrame:frame display:YES];
            NSLog(@"New frame: %@", NSStringFromRect(frame));
        }
		_mostRecentBezelView = [[KCDefaultVisualizerBezelView alloc]
			initWithMaxWidth:maxWidth
			text:charString
			isCommand:NO
			fontSize:[userDefaults floatForKey:@"default.fontSize"]
			fontColor:[userDefaults colorForKey:@"default.textColor"]
			backgroundColor:[userDefaults colorForKey:@"default.bezelColor"]
			];
		[_bezelViews addObject:_mostRecentBezelView];
		frame.size.height += 10 + [_mostRecentBezelView frame].size.height;
		[_mostRecentBezelView setAutoresizingMask:NSViewMinYMargin];
		
		[self setFrame:frame display:YES animate:NO];

		[[self contentView] addSubview:_mostRecentBezelView];
		if ([keystroke isCommand])
			_mostRecentBezelView = nil;
	}
	else
	{
		[_mostRecentBezelView appendString:charString];
		[self _scheduleLineBreak];
	}
}

-(void) abandonCurrentView
{
	_mostRecentBezelView = nil;
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
	int vc = [_runningAnimations count];
	int i;
	for (i = 0; i < vc; ++i)
	{
		NSAnimation* anim = [_runningAnimations objectAtIndex:i];
		[anim stopAnimation];
	}
}

-(void) _resumeAnimations
{
	int vc = [_runningAnimations count];
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
	if (![super init])
		return nil;

	_bezelView = [bezelView retain];
	_window = [_bezelView window];

	return self;
}

-(KCBezelAnimation*) initWithBezelView:(KCDefaultVisualizerBezelView*)bezelView window:(KCDefaultVisualizerWindow*)window
{
	if (![super init])
		return nil;

	_bezelView = [bezelView retain];
	_window = [window retain];

	return self;
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
	if (progress == 1)
		[self release];
}

-(void) animationDidEnd:(NSAnimation*)anim
{
	KCDefaultVisualizerWindow* w = (KCDefaultVisualizerWindow*)[_bezelView window];
	[w removeRunningAnimation:self];
	[_bezelView removeFromSuperview];
	[_bezelView release];
	int deltaY = [_bezelView frame].size.height + 10;
	
	NSArray* a = [[w contentView] subviews];
	int vc = [a count];
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

-(id) initWithMaxWidth:(double)maxWidth text:(NSString*)string isCommand:(BOOL)isCommand fontSize:(double)size fontColor:(NSColor*)fontColor backgroundColor:(NSColor*)color
{
	if (![super initWithFrame:NSMakeRect(0,0,maxWidth,32)])
	{
		return nil;
	}

	_opacity = 1.0;

	_maxWidth = maxWidth;
	_foregroundColor = [fontColor retain];
	_backgroundColor = [color retain];
	_contentText = [string retain];
	_fontSize = size;
	_isCommand = isCommand;

	_textStorage = [[NSTextStorage alloc] initWithString:_contentText];
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
	[w abandonCurrentView];
	KCBezelAnimation* anim = [[KCBezelAnimation alloc] initWithBezelView:self];
	[anim fadeOutOverDuration:[[NSUserDefaults standardUserDefaults] floatForKey:@"default.fadeDuration"]];
	[w addRunningAnimation:anim];
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
			int vc = [a count];
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
	_contentText = [[NSString stringWithFormat:@"%@%@", _contentText, t] retain];
	[_textStorage appendAttributedString:[[NSAttributedString alloc] initWithString:t]];
	[_textStorage setAttributes:[self attributes] range:NSMakeRange(0, [_textStorage length])];
	[self maybeResize];
	[self setNeedsDisplay:YES];
}

-(BOOL) isFlipped
{
	return YES;
}

-(BOOL) isCommand
{
	return _isCommand;
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