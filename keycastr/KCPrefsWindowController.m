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


#import "KCPrefsWindowController.h"
#import "KCAppController.h"

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
	int tag = [item tag];
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
	s.height += [subview frame].size.height;
	[view setFrameSize:s];
	[view addSubview:prefView];
	
	if (_selectedPreferencePane == 1)
	{
		BOOL display = [prefsWindow isVisible];
		NSRect newFrame = [self frameRectWithPin:NSZeroPoint andContentSize:s];
		[prefsWindow setFrame:newFrame display:display animate:display];
	}
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
	toolbarItemIdentifiers = [[NSMutableArray alloc] initWithObjects:NSToolbarFlexibleSpaceItemIdentifier, nil];
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
	[toolbarItemIdentifiers addObject:NSToolbarFlexibleSpaceItemIdentifier];
	
	toolbar = [[NSToolbar alloc] initWithIdentifier:@"KeyCastrToolbar"];
	[toolbar setAllowsUserCustomization:NO];
	[toolbar setAutosavesConfiguration:NO];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setDelegate:self];
	[toolbar setSelectedItemIdentifier:[toolbarItemIdentifiers objectAtIndex:1]];
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

@end
