//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2014-2024 Andrew Kitchen
//
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
#import "KCKeycastrEvent.h"
#import "KCKeystroke.h"
#import "KCMouseEvent.h"
#import "NSUserDefaults+Utility.h"

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

@implementation SvelteVisualizerView {
    NSEventModifierFlags _flags;
	NSString *_displayedString;
}

-(void) drawRect:(NSRect)rect
{
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    
	NSRect frame = [self frame];
	[[NSColor clearColor] setFill];
	NSRectFill(frame);
    
    BOOL shift = [ud boolForKey:@"svelte.display.shift"];
    BOOL control = [ud boolForKey:@"svelte.display.control"];
    BOOL option = [ud boolForKey:@"svelte.display.option"];
    BOOL command = [ud boolForKey:@"svelte.display.command"];

    int segmentCount = shift + control + option + command;
	float oneSegment = floorf(frame.size.width / segmentCount);

    CGFloat rectHeight = segmentCount ? 100 : 70;
    CGFloat rectY = segmentCount ? 0 : 30;
    NSRect drawRect = NSMakeRect(frame.origin.x, rectY, frame.size.width, rectHeight);

	[[ud colorForKey:@"svelte.backgroundColor"] setFill];
	NSBezierPath* bp = [NSBezierPath bezierPath];
	[bp appendRoundedRect:drawRect radius:16];

    if (segmentCount) {
        [bp appendBezierPathWithRect:NSMakeRect(0,30,frame.size.width,1)];
        for (int i = 1; i < segmentCount; i++) {
            [bp appendBezierPathWithRect:NSMakeRect(oneSegment*i,0,1,30)];
        }
    }

	[bp fill];
	
	NSMutableParagraphStyle* ps = [[NSMutableParagraphStyle alloc] init];
    [ps setAlignment:NSTextAlignmentCenter];
	
	NSString* shiftKeyString = [NSString stringWithUTF8String:"\xe2\x87\xa7\x01"];
	NSString* controlKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x83\x01"];
	NSString* altKeyString = [NSString stringWithUTF8String:"\xe2\x8c\xa5\x01"];
	NSString* commandKeyString = [NSString stringWithUTF8String:"\xe2\x8c\x98\x01"];
	NSShadow* shadow = [[NSShadow alloc] init];
	[shadow setShadowColor:[ud colorForKey:@"svelte.textShadowColor"]];
	[shadow setShadowBlurRadius:2];
	[shadow setShadowOffset:NSMakeSize(2,-2)];

	NSSize size;
	NSMutableDictionary* attr = [NSMutableDictionary dictionaryWithObjectsAndKeys:
		[NSFont boldSystemFontOfSize:16], NSFontAttributeName,
		[NSColor whiteColor], NSForegroundColorAttributeName,
		shadow, NSShadowAttributeName,
		ps, NSParagraphStyleAttributeName,
        nil];
    
    NSColor *inactiveModColor = [ud colorForKey:@"svelte.inactiveModifierColor"];
    NSColor *activeModColor = [ud colorForKey:@"svelte.activeModifierColor"];
    
    NSMutableArray<NSAttributedString *> *drawModifiers = [@[] mutableCopy];

    if (shift) {
        NSMutableDictionary *tmpAttr = [attr mutableCopy];
        tmpAttr[NSForegroundColorAttributeName] = (_flags & NSEventModifierFlagShift) ? activeModColor : inactiveModColor;
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:shiftKeyString attributes:tmpAttr];
        [drawModifiers addObject:attrString];
    }

    if (control) {
        NSMutableDictionary *tmpAttr = [attr mutableCopy];
        tmpAttr[NSForegroundColorAttributeName] = (_flags & NSEventModifierFlagControl) ? activeModColor : inactiveModColor;
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:controlKeyString attributes:tmpAttr];
        [drawModifiers addObject:attrString];
    }

    if (option) {
        NSMutableDictionary *tmpAttr = [attr mutableCopy];
        tmpAttr[NSForegroundColorAttributeName] = (_flags & NSEventModifierFlagOption) ? activeModColor : inactiveModColor;
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:altKeyString attributes:tmpAttr];
        [drawModifiers addObject:attrString];
    }

    if (command) {
        NSMutableDictionary *tmpAttr = [attr mutableCopy];
        tmpAttr[NSForegroundColorAttributeName] = (_flags & NSEventModifierFlagCommand) ? activeModColor : inactiveModColor;
        
        NSAttributedString *attrString = [[NSAttributedString alloc] initWithString:commandKeyString attributes:tmpAttr];
        [drawModifiers addObject:attrString];
    }
    
    for (int i = 0; i < [drawModifiers count]; i++) {
        NSAttributedString *modifierString = drawModifiers[i];
        NSSize size = [modifierString.string sizeWithAttributes:attr];
        
        [modifierString drawInRect:NSMakeRect(oneSegment*i,(30 - size.height) / 2.0,oneSegment,size.height)];
    }
    
	if (_displayedString != nil)
	{
        [attr setObject:[ud colorForKey:@"svelte.textColor"] forKey:NSForegroundColorAttributeName];
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

- (void)noteKeyEvent:(KCKeycastrEvent *)event
{
    if (_displayedString) {
        _displayedString = [_displayedString stringByAppendingString:[event convertToString]];


        if (_displayedString.length > 6) {
            NSRange range = NSMakeRange(_displayedString.length - 6, 6);
            _displayedString = [_displayedString substringWithRange:range];
        }
    }
    else {
        _displayedString = [event convertToString];
    }
	[self setNeedsDisplay:YES];
}

-(void) noteFlagsChanged:(NSEventModifierFlags)flags
{
    _displayedString = nil;
    _flags = flags;
	[self setNeedsDisplay:YES];
}

@end


@interface SvelteVisualizer ()

@property (nonatomic, assign) BOOL displayAll;

@end

@implementation SvelteVisualizer {
	NSWindow *_visualizerWindow;
	SvelteVisualizerView *_visualizerView;
}

-(NSString*) visualizerName
{
	return @"Svelte";
}

-(id) init
{
    if (!(self = [super init]))
        return nil;
    
    NSRect r = { 10, 10, 200, 100 };
    _visualizerWindow = [[NSWindow alloc] initWithContentRect:r
                                                    styleMask:NSWindowStyleMaskBorderless
                                                      backing:NSBackingStoreBuffered
                                                        defer:NO];
    [_visualizerWindow setLevel:NSScreenSaverWindowLevel];
    [_visualizerWindow setBackgroundColor:[NSColor clearColor]];
    [_visualizerWindow setMovableByWindowBackground:YES];
    [_visualizerWindow setFrame:r display:NO];
    [_visualizerWindow setFrameAutosaveName:@"svelte visualizerFrame"];
    [_visualizerWindow setFrameUsingName:@"svelte visualizerFrame"];
    [_visualizerWindow setOpaque:NO];
    [_visualizerWindow setCollectionBehavior:NSWindowCollectionBehaviorCanJoinAllSpaces];
    [_visualizerWindow setTitle:@"Svelte Visualizer"];
    
    _visualizerView = [[SvelteVisualizerView alloc] initWithFrame:r];
    [_visualizerWindow setContentView:_visualizerView];
    
    _displayAll = [[[NSUserDefaults standardUserDefaults] valueForKey:@"svelte.displayAll"] boolValue];
    
    // TODO: migrate away from using NSNotificationCenter for this, as it is far too chatty
    __weak typeof(self) weakSelf = self;
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull notification) {
                                                      weakSelf.displayAll = [notification.object boolForKey:@"svelte.displayAll"];
                                                  }];
    
    return self;
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

- (void)noteKeyEvent:(KCKeystroke *)keystroke
{
	if (!_displayAll && ![keystroke isCommand])
		return;
	[_visualizerView noteKeyEvent:keystroke];
}

- (void)noteMouseEvent:(KCMouseEvent *)mouseEvent
{
    NSEventMask eventMask = NSEventMaskFromType(mouseEvent.type);
    if (eventMask & (NSEventMaskLeftMouseDown | NSEventMaskRightMouseDown | NSEventMaskOtherMouseDown)) {
        [_visualizerView noteKeyEvent:mouseEvent];
    }

    if (eventMask & (NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp | NSEventMaskOtherMouseUp)) {
        [_visualizerView noteFlagsChanged:mouseEvent.modifierFlags];
    }

}

- (void)noteFlagsChanged:(NSEventModifierFlags)flags
{
	[_visualizerView noteFlagsChanged:flags];
}

- (IBAction)resetPreferences:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectsWithPrefix:@"svelte."];
}

+ (NSDictionary<NSString *, NSObject *> *)visualizerDefaults {
  return @{
    @"svelte.display.shift" : @YES,
    @"svelte.display.control" : @YES,
    @"svelte.display.option" : @YES,
    @"svelte.display.command" : @YES,
    @"svelte.displayAll" : @YES,
    @"svelte.backgroundColor" : [NSKeyedArchiver
        archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0
                                                               alpha:0.85]
             requiringSecureCoding:NO
                             error:NULL],
    @"svelte.textColor" :
        [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]
                              requiringSecureCoding:NO
                                              error:NULL],
    @"svelte.textShadowColor" :
        [NSKeyedArchiver archivedDataWithRootObject:[NSColor blackColor]
                              requiringSecureCoding:NO
                                              error:NULL],
    @"svelte.inactiveModifierColor" : [NSKeyedArchiver
        archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1
                                                               alpha:0.5]
             requiringSecureCoding:NO
                             error:NULL],
    @"svelte.activeModifierColor" :
        [NSKeyedArchiver archivedDataWithRootObject:[NSColor whiteColor]
                              requiringSecureCoding:NO
                                              error:NULL],
  };
}

@end
