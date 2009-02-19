//
//  KCAppDelegate.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/27/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KCVisualizer.h"
#import "ShortcutRecorder/ShortcutRecorder.h"

@class KCPrefsWindowController;

/** Application Controller


*/
@interface KCAppController : NSObject
{
	IBOutlet NSMenu* statusMenu;
	IBOutlet NSWindow* aboutWindow;
	IBOutlet NSWindow* preferencesWindow;
	IBOutlet KCPrefsWindowController* prefsWindowController;
	NSWindow* visualizerWindow;
	NSStatusItem* statusItem;
	id<KCVisualizer> currentVisualizer;
	IBOutlet SRRecorderControl* shortcutRecorder;
	IBOutlet NSMenuItem* statusShortcutItem;
	BOOL _isCapturing;
	BOOL _allowToggle;
	int _startupIconPreference;
	BOOL _displayedRestartAlertPanel;
}

-(IBAction) orderFrontKeyCastrAboutPanel:(id)sender;
-(IBAction) orderFrontKeyCastrPreferencesPanel:(id)sender;
-(IBAction) toggleRecording:(id)sender;
-(IBAction) pretendToDoSomethingImportant:(id)sender;
-(IBAction) changeIconPreference:(id)sender;

-(BOOL) isCapturing;
-(void) setIsCapturing:(BOOL)isCapturing;
-(void) registerVisualizers;

-(NSStatusItem*) createStatusItem;

-(NSArray*) availableVisualizerNames;

-(NSString*) currentVisualizerName;
-(void) setCurrentVisualizerName:(NSString*)visualizerName;

-(id<KCVisualizer>) currentVisualizer;
-(void) setCurrentVisualizer:(id<KCVisualizer>)visualizer;


@end
