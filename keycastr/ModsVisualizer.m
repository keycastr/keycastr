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


#import "ModsVisualizer.h"
#import "NSBezierPath+RoundedRect.h"

@implementation ModsVisualizerFactory

-(NSString*) visualizerNibName
{
	return @"Mods";
}

-(Class) visualizerClass
{
	return [ModsVisualizer class];
}

-(NSString*) visualizerName
{
	return @"Mods";
}

@end

@implementation ModsVisualizerView

-(void) drawRect:(NSRect)rect
{
	NSRect frame = [self frame];
	NSRect bgFrame = [self frame];
	float oneQuarter = floorf(frame.size.width / 4);
	bgFrame.size.width = 0;
	CGFloat x = frame.size.width, y;
	NSSize size;

	bgFrame.origin.x = frame.size.width;
	[[NSColor clearColor] setFill];
	NSRectFill(frame);

	if (_flags & NSShiftKeyMask) {
		bgFrame.size.width += oneQuarter;
		bgFrame.origin.x -= oneQuarter;
	}

	if (_flags & NSControlKeyMask) {
		bgFrame.size.width += oneQuarter;
		bgFrame.origin.x -= oneQuarter;
	}

	if (_flags & NSAlternateKeyMask) {
		bgFrame.size.width += oneQuarter;
		bgFrame.origin.x -= oneQuarter;
	}

	if (_flags & NSCommandKeyMask) {
		bgFrame.size.width += oneQuarter;
		bgFrame.origin.x -= oneQuarter;
	}

	if (bgFrame.size.width > 0) {
        [[NSColor colorWithCalibratedWhite:0 alpha:0.75] setFill];
        NSBezierPath* bp = [NSBezierPath bezierPath];
        [bp appendRoundedRect:bgFrame radius:10];
        [bp fill];
	}

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

	NSMutableDictionary* attr = [@{
		NSFontAttributeName:            [NSFont boldSystemFontOfSize:80],
		NSForegroundColorAttributeName: [NSColor colorWithCalibratedWhite:1 alpha:0.8],
		NSShadowAttributeName:          shadow,
		NSParagraphStyleAttributeName:  [ps autorelease]
	} mutableCopy];

	if (_flags & NSShiftKeyMask) {
		size = [shiftKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[shiftKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

	if (_flags & NSControlKeyMask) {
		size = [controlKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[controlKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

	if (_flags & NSAlternateKeyMask) {
		size = [altKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[altKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}

	if (_flags & NSCommandKeyMask) {
		size = [commandKeyString sizeWithAttributes:attr];
		y = (frame.size.height - size.height) / 2.0;
		x -= oneQuarter;
		[commandKeyString drawInRect:NSMakeRect(x, y, oneQuarter, size.height) withAttributes:attr];
	}
}

-(void) noteFlagsChanged:(uint32_t)flags
{
    _flags = flags;
    [self setNeedsDisplay:YES];
}

@end


@implementation ModsVisualizer

-(NSString*) visualizerName
{
	return @"Mods";
}

-(id) init
{
	if (!(self = [super init]))
		return nil;

	NSRect r = { 10, 10, 400, 100 };
	_visualizerWindow = [[NSWindow alloc]
		initWithContentRect:r
		styleMask:NSBorderlessWindowMask
		backing:NSBackingStoreBuffered
		defer:NO];
	[_visualizerWindow setLevel:NSScreenSaverWindowLevel];
	[_visualizerWindow setBackgroundColor:[NSColor clearColor]];
	[_visualizerWindow setMovableByWindowBackground:YES];
	[_visualizerWindow setFrame:r display:NO];
	[_visualizerWindow setFrameAutosaveName:@"svelte visualizerFrame"];
	[_visualizerWindow setFrameUsingName:@"svelte visualizerFrame"];
	[_visualizerWindow setOpaque:NO];

	_visualizerView = [[ModsVisualizerView alloc] initWithFrame:r];
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

-(void) noteFlagsChanged:(uint32_t)flags
{
	[_visualizerView noteFlagsChanged:flags];
}

@end
