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


#import "SvelteVisualizer.h"
#import "NSBezierPath+RoundedRect.h"

@implementation SvelteVisualizerFactory

-(NSString*) visualizerNibName
{
	return @"Svelte";
}

-(Class) visualizerClass
{
	return [SvelteVisualizer class];
}

-(NSString*) visualizerName
{
	return @"Svelte";
}

@end

@implementation SvelteVisualizerView

-(void) drawRect:(NSRect)rect
{
	NSRect frame = [self frame];
	[[NSColor clearColor] setFill];
	NSRectFill(frame);

	float oneQuarter = floorf(frame.size.width / 4);

	[[NSColor colorWithCalibratedWhite:0 alpha:0.75] setFill];
	NSBezierPath* bp = [NSBezierPath bezierPath];
	[bp appendRoundedRect:frame radius:16];
	[bp appendBezierPathWithRect:NSMakeRect(0,30,frame.size.width,1)];
	[bp appendBezierPathWithRect:NSMakeRect(oneQuarter*1,0,1,30)];
	[bp appendBezierPathWithRect:NSMakeRect(oneQuarter*2,0,1,30)];
	[bp appendBezierPathWithRect:NSMakeRect(oneQuarter*3,0,1,30)];
	[bp fill];
	
	NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle alloc] init];
	[ps setAlignment:NSCenterTextAlignment];
	
	NSString* shiftKeyString = [NSString stringWithUTF8String:"\xe2\x87\xa7\x01"];
	NSString* controlKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x83\x01"];
	NSString* altKeyString = [NSString stringWithUTF8String:"\xe2\x8c\xa5\x01"];
	NSString* commandKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x98\x01"];
	NSShadow* shadow = [[[NSShadow alloc] init] autorelease];
	[shadow setShadowColor:[NSColor blackColor]];
	[shadow setShadowBlurRadius:2];
	[shadow setShadowOffset:NSMakeSize(2,-2)];

	NSSize size;
	NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:16], NSFontAttributeName,
		[NSColor whiteColor], NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		[ps autorelease], NSParagraphStyleAttributeName,
        nil];

	if (_flags & NSShiftKeyMask)
		[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else
		[attr setObject:[NSColor colorWithCalibratedWhite:1 alpha:0.5] forKey:NSForegroundColorAttributeName];
	size = [shiftKeyString sizeWithAttributes:attr];
	[shiftKeyString drawInRect:NSMakeRect(0,(30 - size.height) / 2.0,oneQuarter,size.height) withAttributes:attr];

	if (_flags & NSControlKeyMask)
		[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else
		[attr setObject:[NSColor colorWithCalibratedWhite:1 alpha:0.5] forKey:NSForegroundColorAttributeName];
	size = [controlKeyString sizeWithAttributes:attr];
	[controlKeyString drawInRect:NSMakeRect(oneQuarter,(30 - size.height) / 2.0,oneQuarter,size.height) withAttributes:attr];

	if (_flags & NSAlternateKeyMask)
		[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else
		[attr setObject:[NSColor colorWithCalibratedWhite:1 alpha:0.5] forKey:NSForegroundColorAttributeName];
	size = [altKeyString sizeWithAttributes:attr];
	[altKeyString drawInRect:NSMakeRect(oneQuarter*2,(30 - size.height) / 2.0,oneQuarter,size.height) withAttributes:attr];

	if (_flags & NSCommandKeyMask)
		[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
	else
		[attr setObject:[NSColor colorWithCalibratedWhite:1 alpha:0.5] forKey:NSForegroundColorAttributeName];
	size = [commandKeyString sizeWithAttributes:attr];
	[commandKeyString drawInRect:NSMakeRect(oneQuarter*3,(30 - size.height) / 2.0,oneQuarter,size.height) withAttributes:attr];
	
	if (_displayedString != nil)
	{
		[attr setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		float fontSize = 48;
		[attr setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
		
		size = [_displayedString sizeWithAttributes:attr];
		while (size.width > frame.size.width - 10)
		{
			fontSize -= 1.0;
			[attr setObject:[NSFont systemFontOfSize:fontSize] forKey:NSFontAttributeName];
			size = [_displayedString sizeWithAttributes:attr];
		}
		[_displayedString drawInRect:NSMakeRect(0,30+(frame.size.height-30 - size.height)/2.0,frame.size.width,size.height) withAttributes:attr];
	}
}

-(void) noteKeyEvent:(KCKeystroke*)keystroke
{
    if (_displayedString) {
        [_displayedString autorelease];
        _displayedString = [[_displayedString stringByAppendingString:[keystroke convertToString]] retain];


        if (_displayedString.length > 6) {
            NSRange range = NSMakeRange(_displayedString.length - 6, 6);
            [_displayedString autorelease];
            _displayedString = [[_displayedString substringWithRange:range] retain];
        }
    }
    else {
        _displayedString = [[keystroke convertToString] retain];
    }
	[self setNeedsDisplay:YES];
}

-(void) noteFlagsChanged:(uint32_t)flags
{
    [_displayedString autorelease];
    _displayedString = nil;
    _flags = flags;
	[self setNeedsDisplay:YES];
}

@end


@implementation SvelteVisualizer

-(NSString*) visualizerName
{
	return @"Svelte";
}

-(id) init
{
	if (!(self = [super init]))
		return nil;

	NSRect r = { 10, 10, 200, 100 };
	_visualizerWindow = [[NSWindow alloc]
		initWithContentRect:r
		styleMask:NSBorderlessWindowMask
		backing:NSBackingStoreBuffered
		defer:NO];
	[_visualizerWindow setLevel:NSScreenSaverWindowLevel];
	[_visualizerWindow setBackgroundColor:[NSColor blueColor]];
	[_visualizerWindow setMovableByWindowBackground:YES];
	[_visualizerWindow setFrame:r display:NO];
	[_visualizerWindow setFrameAutosaveName:@"svelte visualizerFrame"];
	[_visualizerWindow setFrameUsingName:@"svelte visualizerFrame"];
	[_visualizerWindow setOpaque:NO];

	_visualizerView = [[SvelteVisualizerView alloc] initWithFrame:r];
	[_visualizerWindow setContentView:_visualizerView];

    _displayAll = [[[NSUserDefaults standardUserDefaults] valueForKey:@"svelte.displayAll"] boolValue];

    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
 object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
     _displayAll = [[[NSUserDefaults standardUserDefaults] valueForKey:@"svelte.displayAll"] boolValue];
 }];

	return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_visualizerWindow release];
    [_visualizerView release];
    [super dealloc];
}

-(void) showVisualizer:(id)sender
{
	[_visualizerWindow orderFront:self];
}

-(void) hideVisualizer:(id)sender
{
	[_visualizerWindow orderOut:self];
}

-(void) deactivateVisualizer:(id)sender
{
	[_visualizerWindow orderOut:self];
}

-(void) noteKeyEvent:(KCKeystroke*)keystroke
{
	if (!_displayAll && ![keystroke isCommand])
		return;
	[_visualizerView noteKeyEvent:keystroke];
}

-(void) noteFlagsChanged:(uint32_t)flags
{
	[_visualizerView noteFlagsChanged:flags];
}

@end
