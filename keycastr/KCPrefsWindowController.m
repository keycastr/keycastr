//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2014-2023 Andrew Kitchen
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


#import "KCPrefsWindowController.h"
#import "KCAppController.h"
#import "KCColorValueTransformer.h"
#import "KCMouseEventVisualizer.h"
#import "KCVisualizer.h"

static CGFloat const kKCMouseEffectsBoxMargin = 12.0;

@implementation KCPrefsWindowController

-(NSArray*) toolbarAllowedItemIdentifiers:(NSToolbar*)toolbar
{
	return toolbarItemIdentifiers;
}

-(NSArray*) toolbarDefaultItemIdentifiers:(id)sender
{
	return toolbarItemIdentifiers;
}

-(NSArray*) toolbarSelectableItemIdentifiers:(id)sender
{
	return toolbarItemIdentifiers;
}

-(NSToolbarItem*) toolbar:(NSToolbar*)toolbar itemForItemIdentifier:(NSString*)itemIdentifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return [toolbarItems objectForKey:itemIdentifier];
}

-(NSRect) frameRectWithPin:(NSPoint)point andContentSize:(NSSize)size
{
	NSRect oldFrame = [prefsWindow frame];
	NSRect newFrame = [prefsWindow frameRectForContentRect:NSMakeRect(0,0,size.width,size.height)];
	newFrame.origin.x = (oldFrame.origin.x + oldFrame.size.width / 2.0) - newFrame.size.width / 2.0;
	newFrame.origin.y = (oldFrame.origin.y + oldFrame.size.height) - newFrame.size.height;
	return newFrame;
}

-(void) toolbarItemSelected:(id)sender
{
	NSToolbarItem* item = sender;
	
	// Otherwise, switch preference panes:
	NSInteger tag = [item tag];
	if (tag == _selectedPreferencePane)
		return;
	
	_selectedPreferencePane = tag;
	NSView* newView = [preferenceViews objectAtIndex:tag];
	NSSize newSize = [newView frame].size;
	NSRect newFrame = [self frameRectWithPin:NSZeroPoint andContentSize:newSize];

	[newView setFrameOrigin:NSZeroPoint];
	[newView setAutoresizingMask:NSViewMaxYMargin | NSViewWidthSizable | NSViewMinXMargin | NSViewMaxXMargin];
	[prefsWindow setContentView:newView];
	[prefsWindow setTitle:[item label]];
	[prefsWindow setFrame:newFrame display:YES animate:YES];
}

-(void) changeVisualizerFrom:(id<KCVisualizer>)old to:(id<KCVisualizer>)new
{
	if (old == new)
		return;
	if (new == nil)
		return;
	if (old != nil)
	{
		[[old preferencesView] removeFromSuperview];
	}

	// we assume it's the second item in the array
	NSView* view = [preferenceViews objectAtIndex:1];
	NSView* subview = [[view subviews] objectAtIndex:0];
	NSView* prefView = [new preferencesView];
	NSSize s = [prefView frame].size;
    // TODO: this is overly tightly coupled to the Display tab's layout
	s.height += [subview frame].size.height * 2.0;
	[view setFrameSize:s];
	[view addSubview:prefView];

	if (_selectedPreferencePane == 1)
	{
		BOOL display = [prefsWindow isVisible];
		NSRect newFrame = [self frameRectWithPin:NSZeroPoint andContentSize:s];
		[prefsWindow setFrame:newFrame display:display animate:display];
	}
}

#pragma mark - Mouse Effects controls

// Layout constants — all dimensions are in points, all using absolute frames.
static const CGFloat kKCRowHeight = 24.0;
static const CGFloat kKCRowSpacing = 10.0;
static const CGFloat kKCBoxTopPadding = 14.0;
static const CGFloat kKCBoxBottomPadding = 14.0;
static const CGFloat kKCLabelWidth = 170.0;
static const CGFloat kKCLabelToControlGap = 8.0;
static const CGFloat kKCInnerHorizontalPadding = 16.0;
static const CGFloat kKCRowCount = 6;
// NSBox with NSAtTop title position consumes ~22pt for the title bar at the top of its frame.
static const CGFloat kKCBoxTitleReserve = 24.0;

-(CGFloat) mouseEffectsContentHeight
{
	return kKCBoxTopPadding + kKCRowCount * kKCRowHeight + (kKCRowCount - 1) * kKCRowSpacing + kKCBoxBottomPadding;
}

-(CGFloat) mouseEffectsBoxHeight
{
	return [self mouseEffectsContentHeight] + kKCBoxTitleReserve;
}

-(NSTextField*) labelWithFrame:(NSRect)frame string:(NSString*)str
{
	NSTextField* label = [[[NSTextField alloc] initWithFrame:frame] autorelease];
	[label setStringValue:str];
	[label setEditable:NO];
	[label setBezeled:NO];
	[label setDrawsBackground:NO];
	[label setSelectable:NO];
	[label setAlignment:NSTextAlignmentRight];
	return label;
}

-(NSColorWell*) colorWellWithFrame:(NSRect)frame forKey:(NSString*)defaultsKey
{
	NSColorWell* well = [[[NSColorWell alloc] initWithFrame:frame] autorelease];
	NSDictionary* options = @{
		NSValueTransformerNameBindingOption: NSStringFromClass([KCColorValueTransformer class]),
	};
	[well bind:NSValueBinding
	  toObject:[NSUserDefaultsController sharedUserDefaultsController]
   withKeyPath:[@"values." stringByAppendingString:defaultsKey]
	   options:options];
	return well;
}

-(NSBox*) buildMouseEffectsBoxWithWidth:(CGFloat)width
{
	CGFloat boxHeight = [self mouseEffectsBoxHeight];
	NSBox* box = [[[NSBox alloc] initWithFrame:NSMakeRect(0, 0, width, boxHeight)] autorelease];
	[box setTitle:@"Mouse Effect"];
	[box setBoxType:NSBoxPrimary];
	[box setTitlePosition:NSAtTop];

	NSView* content = [box contentView];
	NSRect contentFrame = [content frame];
	CGFloat innerWidth = contentFrame.size.width - 2 * kKCInnerHorizontalPadding;
	CGFloat controlX = kKCInnerHorizontalPadding + kKCLabelWidth + kKCLabelToControlGap;
	CGFloat controlWidth = innerWidth - kKCLabelWidth - kKCLabelToControlGap;
	if (controlWidth < 120) controlWidth = 120;

	// Place rows top-to-bottom in Cocoa coordinates (y decreases as we go down).
	CGFloat topY = contentFrame.size.height - kKCBoxTopPadding - kKCRowHeight;
	CGFloat rowStride = kKCRowHeight + kKCRowSpacing;

	NSRect (^labelRectAt)(NSInteger) = ^NSRect(NSInteger rowIndex) {
		return NSMakeRect(kKCInnerHorizontalPadding, topY - rowIndex * rowStride, kKCLabelWidth, kKCRowHeight);
	};
	NSRect (^controlRectAt)(NSInteger) = ^NSRect(NSInteger rowIndex) {
		return NSMakeRect(controlX, topY - rowIndex * rowStride, controlWidth, kKCRowHeight);
	};

	// Row 0: Mouse Effect popup
	[content addSubview:[self labelWithFrame:labelRectAt(0) string:@"Mouse Effect:"]];
	NSRect popupFrame = controlRectAt(0);
	popupFrame.size.width = MIN(controlWidth, 200.0);
	NSPopUpButton* popup = [[[NSPopUpButton alloc] initWithFrame:popupFrame pullsDown:NO] autorelease];
	[popup bind:NSContentValuesBinding
	   toObject:appController
	withKeyPath:@"availableMouseEffectNames"
		options:nil];
	[popup bind:NSSelectedValueBinding
	   toObject:[NSUserDefaultsController sharedUserDefaultsController]
	withKeyPath:[@"values." stringByAppendingString:kKCMouseEffectKey]
		options:nil];
	[content addSubview:popup];

	// Row 1: Mouse Effect Color 1
	[content addSubview:[self labelWithFrame:labelRectAt(1) string:@"Mouse Effect Color 1:"]];
	NSRect color1Frame = NSMakeRect(controlX, topY - 1 * rowStride, 60.0, kKCRowHeight);
	[content addSubview:[self colorWellWithFrame:color1Frame forKey:kKCMouseEffectColor1Key]];

	// Row 2: Mouse Effect Color 2
	[content addSubview:[self labelWithFrame:labelRectAt(2) string:@"Mouse Effect Color 2:"]];
	NSRect color2Frame = NSMakeRect(controlX, topY - 2 * rowStride, 60.0, kKCRowHeight);
	[content addSubview:[self colorWellWithFrame:color2Frame forKey:kKCMouseEffectColor2Key]];

	// Row 3: Density (line/core thickness)
	[self addSliderRowToContent:content
				   labelString:@"Mouse Effect Density:"
					  labelRect:labelRectAt(3)
					controlX:controlX
					controlY:topY - 3 * rowStride
				 controlWidth:controlWidth
					 minValue:1.0
					 maxValue:12.0
				   defaultsKey:kKCMouseEffectDensityKey
					  suffix:@""];

	// Row 4: Diameter (outer extent of the effect)
	[self addSliderRowToContent:content
				   labelString:@"Mouse Effect Diameter:"
					  labelRect:labelRectAt(4)
					controlX:controlX
					controlY:topY - 4 * rowStride
				 controlWidth:controlWidth
					 minValue:20.0
					 maxValue:160.0
				   defaultsKey:kKCMouseEffectDiameterKey
					  suffix:@" pt"];

	// Row 5: Duration
	[self addSliderRowToContent:content
				   labelString:@"Mouse Effect Duration:"
					  labelRect:labelRectAt(5)
					controlX:controlX
					controlY:topY - 5 * rowStride
				 controlWidth:controlWidth
					 minValue:0.1
					 maxValue:2.0
				   defaultsKey:kKCMouseEffectDurationKey
					  suffix:@" s"];

	return box;
}

-(void) addSliderRowToContent:(NSView*)content
				   labelString:(NSString*)labelStr
					 labelRect:(NSRect)labelRect
					  controlX:(CGFloat)controlX
					  controlY:(CGFloat)controlY
				  controlWidth:(CGFloat)controlWidth
					  minValue:(double)minValue
					  maxValue:(double)maxValue
				   defaultsKey:(NSString*)defaultsKey
						suffix:(NSString*)suffix
{
	[content addSubview:[self labelWithFrame:labelRect string:labelStr]];

	CGFloat readoutWidth = 70.0;
	CGFloat sliderWidth = controlWidth - readoutWidth - 8.0;
	if (sliderWidth < 80) sliderWidth = 80;

	NSSlider* slider = [[[NSSlider alloc] initWithFrame:NSMakeRect(controlX, controlY, sliderWidth, kKCRowHeight)] autorelease];
	[slider setMinValue:minValue];
	[slider setMaxValue:maxValue];
	[slider bind:NSValueBinding
		toObject:[NSUserDefaultsController sharedUserDefaultsController]
	 withKeyPath:[@"values." stringByAppendingString:defaultsKey]
		 options:@{NSContinuouslyUpdatesValueBindingOption: @YES}];
	[content addSubview:slider];

	NSTextField* field = [[[NSTextField alloc] initWithFrame:NSMakeRect(controlX + sliderWidth + 8.0, controlY, readoutWidth, kKCRowHeight)] autorelease];
	[field setEditable:YES];
	[field setBezeled:YES];
	[field setBezelStyle:NSTextFieldRoundedBezel];
	[field setDrawsBackground:YES];
	[field setSelectable:YES];
	[field setAlignment:NSTextAlignmentRight];
	NSNumberFormatter* fmt = [[[NSNumberFormatter alloc] init] autorelease];
	[fmt setMinimumFractionDigits:2];
	[fmt setMaximumFractionDigits:2];
	[fmt setMinimum:@(minValue)];
	[fmt setMaximum:@(maxValue)];
	if ([suffix length] > 0) {
		[fmt setPositiveSuffix:suffix];
	}
	[field setFormatter:fmt];
	[field bind:NSValueBinding
	   toObject:[NSUserDefaultsController sharedUserDefaultsController]
	withKeyPath:[@"values." stringByAppendingString:defaultsKey]
		options:@{NSContinuouslyUpdatesValueBindingOption: @YES}];
	[content addSubview:field];
}

-(NSView*) buildMouseEffectsTabContentView
{
	if (_mouseEffectsBox != nil) {
		// Already built; reuse parent.
		return [_mouseEffectsBox superview];
	}

	// Match the General/Display tabs' typical width so the prefs window doesn't visibly resize when switching to ours.
	CGFloat tabWidth = 460.0;
	if ([preferenceViews count] > 0) {
		tabWidth = [[preferenceViews objectAtIndex:0] frame].size.width;
	}

	CGFloat boxWidth = tabWidth - 2 * kKCMouseEffectsBoxMargin;
	NSBox* box = [self buildMouseEffectsBoxWithWidth:boxWidth];
	CGFloat boxHeight = [box frame].size.height;

	CGFloat tabHeight = boxHeight + 2 * kKCMouseEffectsBoxMargin;
	NSView* contentView = [[[NSView alloc] initWithFrame:NSMakeRect(0, 0, tabWidth, tabHeight)] autorelease];

	NSRect boxFrame = NSMakeRect(kKCMouseEffectsBoxMargin,
								 kKCMouseEffectsBoxMargin,
								 boxWidth,
								 boxHeight);
	[box setFrame:boxFrame];
	[box setAutoresizingMask:NSViewWidthSizable];
	[contentView addSubview:box];

	_mouseEffectsBox = [box retain];
	return contentView;
}

-(void) registerMouseEffectsTab
{
	if (_mouseEffectsBox != nil) return;

	NSView* contentView = [self buildMouseEffectsTabContentView];
	NSString* identifier = @"Mouse";
	NSInteger tag = [preferenceViews count];

	NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:identifier] autorelease];
	[item setLabel:identifier];

	NSImage* icon = nil;
	if (@available(macOS 11.0, *)) {
		icon = [NSImage imageWithSystemSymbolName:@"computermouse" accessibilityDescription:@"Mouse"];
	}
	if (icon == nil) {
		icon = [NSImage imageNamed:NSImageNameComputer];
	}
	[item setImage:icon];
	[item setTarget:self];
	[item setAction:@selector(toolbarItemSelected:)];
	[item setTag:tag];

	// Place Mouse before the last existing identifier (Update) so the toolbar reads
	// General | Display | Mouse | Update.  preferenceViews index (= tag) stays at the end.
	NSUInteger insertIndex = [toolbarItemIdentifiers count];
	if (insertIndex > 0) {
		insertIndex -= 1;
	}
	[toolbarItemIdentifiers insertObject:identifier atIndex:insertIndex];
	[toolbarItems setObject:item forKey:identifier];
	[preferenceViews addObject:contentView];
}

-(void) visualizerChanged:(NSNotification*)notification
{
	id<KCVisualizer> old = [[notification userInfo] valueForKey:@"oldVisualizer"];
	id<KCVisualizer> new = [[notification userInfo] valueForKey:@"newVisualizer"];
	[self changeVisualizerFrom:old to:new];
}

-(void) nudge
{
	[tabView retain];
	[tabView removeFromSuperview];
	toolbarItemIdentifiers = [[NSMutableArray alloc] init];
	preferenceViews = [[NSMutableArray alloc] init];
	toolbarItems = [[NSMutableDictionary alloc] init];
	int tag = 0;
	int i = 0;
	for (i = 0; i < [[tabView tabViewItems] count]; ++i)
	{
		NSTabViewItem* tvi = [[tabView tabViewItems] objectAtIndex:i];
		// Get the subview within this tab view.
		NSView* currentView = [[[tvi view] subviews] objectAtIndex:0];
		
		// If there is no subview, skip this tab.
		if (!currentView)
			continue;

		[preferenceViews addObject:currentView];

		NSString* itemIdentifier = [tvi label];
		[toolbarItemIdentifiers addObject:itemIdentifier];

		// Create a toolbar item for this preference pane.
		NSToolbarItem* item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
		[item setLabel:itemIdentifier];
		[item setImage:[NSImage imageNamed:[NSString stringWithFormat:@"%@Icon", itemIdentifier]]];
		[item setTarget:self];
		[item setAction:@selector(toolbarItemSelected:)];
		[item setTag:tag];
		[toolbarItems setObject:item forKey:[tvi label]];
		tag++;
	}

	// Append our programmatic "Mouse" tab before the toolbar is built so it shows up in the toolbar.
	[self registerMouseEffectsTab];

	toolbar = [[NSToolbar alloc] initWithIdentifier:@"KeyCastrToolbar"];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	[toolbar setSelectedItemIdentifier:[toolbarItemIdentifiers objectAtIndex:0]];
	[prefsWindow setToolbar:toolbar];

	NSView* currentView = [preferenceViews objectAtIndex:0];
	[prefsWindow setTitle:@"General"];
	[prefsWindow setContentSize:[currentView frame].size];
	[prefsWindow center];
	[prefsWindow setContentView:currentView];

	// fixup the dimensions of the Display preference pane based on the current visualizer
	id<KCVisualizer> v = [appController currentVisualizer];
	[self changeVisualizerFrom:nil to:v];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(visualizerChanged:) name:@"KCVisualizerChanged" object:nil];
	_selectedPreferencePane = 0;
}

- (void)dealloc {
    [toolbar release];
    [toolbarItems release];
    [toolbarItemIdentifiers release];
    [preferenceViews release];
    [_mouseEffectsBox release];
    [_originalDisplayTab release];
    [_displayWrapper release];
    [super dealloc];
}

@end
