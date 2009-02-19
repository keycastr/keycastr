//
//  KCPrefsWindowController.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class KCAppController;
@protocol KCVisualizer;

@interface KCPrefsWindowController : NSObject
{
	IBOutlet NSWindow* prefsWindow;
	IBOutlet NSTabView* tabView;
	IBOutlet KCAppController* appController;
	NSMutableDictionary* toolbarItems;
	NSMutableArray* toolbarItemIdentifiers;
	NSToolbar* toolbar;
	NSMutableArray* preferenceViews;
	int _selectedPreferencePane;
}

-(void) changeVisualizerFrom:(id<KCVisualizer>)old to:(id<KCVisualizer>)new;
-(void) nudge;

@end
