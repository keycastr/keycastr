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


#import "KCAppController.h"
#import "KCKeyboardTap.h"
#import "KCDefaultVisualizer.h"
#import "KCPrefsWindowController.h"
#import "ShortcutRecorder/SRKeyCodeTransformer.h"

static NSString* kKCPrefCapturingHotKey = @"capturingHotKey";
static NSString* kKCPrefVisibleAtLaunch = @"alwaysShowPrefs";
static NSString* kKCPrefDisplayIcon = @"displayIcon";
static NSString* kKCPrefSelectedVisualizer = @"selectedVisualizer";

@implementation KCAppController

#pragma mark -
#pragma mark Startup Procedures

-(id) init
{
	if (![super init])
		return nil;

	[NSColor setIgnoresAlpha:NO];

	_allowToggle = true;
	_isCapturing = true;
	_startupIconPreference = [[NSUserDefaults standardUserDefaults] integerForKey:kKCPrefDisplayIcon];

	return self;
}

-(void) awakeFromNib
{
	[NSApp activateIgnoringOtherApps:TRUE];
	[self registerVisualizers];
	[self setCurrentVisualizerName:[[NSUserDefaults standardUserDefaults] objectForKey:kKCPrefSelectedVisualizer]];
	[self setIsCapturing:YES];

	// Bootstrap key capturing hotkey from preferences
	KeyCombo kc;
	kc.code = -1;
	kc.flags = 0;
	
	NSData* d = [[NSUserDefaults standardUserDefaults] dataForKey:kKCPrefCapturingHotKey];
	if (d != nil)
		[d getBytes:&kc length:sizeof(kc)];
		
		NSLog( @"pref modifiers = %08x; keycode = %d", kc.flags, kc.code );

	[shortcutRecorder setKeyCombo:kc];
	_allowToggle = YES;

	// Set up observation of keystroke events
	[[KCKeyboardTap sharedKeyboardTap] setDelegate:self];

	[prefsWindowController nudge];
	// Show the preferences window if desired
	if ([[NSUserDefaults standardUserDefaults] boolForKey:kKCPrefVisibleAtLaunch])
	{
		[preferencesWindow center];
		[preferencesWindow makeKeyAndOrderFront:self];
	}
	
	if (_startupIconPreference & 0x01)
		[self createStatusItem];
}

-(void) keyboardTap:(KCKeyboardTap*)tap noteKeystroke:(KCKeystroke*)keystroke
{
	KeyCombo kc = [shortcutRecorder keyCombo];
	if ([keystroke keyCode] == kc.code && ([keystroke modifiers] & (NSControlKeyMask | NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)) == (kc.flags & (NSControlKeyMask | NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)))
	{
NSLog(@"Toggle keystroke hit");
		if (_allowToggle)
		{
NSLog(@"(toggling)");
			[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(stopPretending:) object:nil];
			[self toggleRecording:self];
		}
else NSLog(@"(not toggling)");
		return;
	}
	
	_allowToggle = true;
	
	if (!_isCapturing)
		return;

	if (currentVisualizer != nil)
		[currentVisualizer noteKeyEvent:keystroke];
}

-(void) keyboardTap:(KCKeyboardTap*)tap noteFlagsChanged:(uint32_t)flags
{
	if (currentVisualizer != nil)
		[currentVisualizer noteFlagsChanged:flags];
}

-(NSStatusItem*) createStatusItem
{
	if (statusItem == nil)
	{
		statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:30] retain];
		[statusItem setMenu:statusMenu];
		[statusItem setImage:(_isCapturing
			? [NSImage imageNamed:@"KeyCastrStatusItemActive"]
			: [NSImage imageNamed:@"KeyCastrStatusItemInactive"])];
		[statusItem setHighlightMode:YES];
	}
	return statusItem;
}

-(void) deleteStatusItem
{
	if (statusItem != nil)
	{
		[statusItem release];
		statusItem = nil;
	}
}

-(void) registerVisualizerClass:(Class)c
{
	KCVisualizerFactory* factory = [[c alloc] init];
	[KCVisualizer registerVisualizerFactory:factory withName:[factory visualizerName]];
}

-(void) loadPluginsFromDirectory:(NSString*)path
{
	NSDirectoryEnumerator *dir = [[NSFileManager defaultManager] enumeratorAtPath:path];
	NSString *file = nil;
	while (file = [dir nextObject])
	{
		[dir skipDescendents];
		if (![file hasSuffix:@".kcplugin"])
			continue;
		NSBundle *b = [NSBundle bundleWithPath:[path stringByAppendingPathComponent:file]];
		if ([b load] == NO)
		{
			NSLog( @"Could not load %@ from %@", file, path );
		}
		else
		{
			[self registerVisualizerClass:[b principalClass]];
		}
	}
}

-(void) registerVisualizers
{
	// register the built-in default visualizer
//	id factory = [[[KCDefaultVisualizerFactory alloc] init] autorelease];
//	[KCVisualizer registerVisualizerFactory:factory withName:[factory visualizerName]];
	
	// register other visualizers from plug-in paths
	NSMutableArray *pluginSearchPaths = [NSMutableArray arrayWithObject:[[NSBundle mainBundle] builtInPlugInsPath]];

	NSArray *librarySearchPaths = NSSearchPathForDirectoriesInDomains( NSLibraryDirectory, NSAllDomainsMask - NSSystemDomainMask, YES );
	if (librarySearchPaths != nil)
	{
		NSEnumerator *searchPathEnum = [librarySearchPaths objectEnumerator];
		NSString *currPath;
		while (currPath = [searchPathEnum nextObject])
			[pluginSearchPaths addObject:[currPath stringByAppendingPathComponent:@"Application Support/KeyCastr/PlugIns"]];
	}
	NSEnumerator *iter = [pluginSearchPaths objectEnumerator];
	NSString *path = nil;
	while (path = [iter nextObject])
	{
		[self loadPluginsFromDirectory:path];
	}
}

-(void) changeKeyComboTo:(KeyCombo)kc
{
	_allowToggle = false;
	if (kc.code != -1)
	{
		SRKeyCodeTransformer* xformer = [[SRKeyCodeTransformer alloc] init];
		[statusShortcutItem setKeyEquivalent:[xformer transformedValue:[NSNumber numberWithInt:kc.code]]];
		[statusShortcutItem setKeyEquivalentModifierMask:kc.flags];
	}
	else
	{
		[statusShortcutItem setKeyEquivalent:@""];
	}
}

-(void) orderFrontKeyCastrAboutPanel:(id)sender
{
	[aboutWindow center];
	[aboutWindow makeKeyAndOrderFront:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

-(void) orderFrontKeyCastrPreferencesPanel:(id)sender
{
	[preferencesWindow makeKeyAndOrderFront:sender];
	[NSApp activateIgnoringOtherApps:YES];
}

-(void) toggleRecording:(id)sender
{
	[self setIsCapturing:![self isCapturing]];
}

-(void) stopPretending:(id)what
{
	_allowToggle = true;
	NSLog(@"Timer expired, toggling recording");
	[self toggleRecording:self];
}

-(void) pretendToDoSomethingImportant:(id)sender
{
	_allowToggle = false;
	[self performSelector:@selector(stopPretending:) withObject:nil afterDelay:0.1];
	NSLog(@"Menu item hit, waiting 100 ms");
}

-(NSString*) currentVisualizerName
{
	if (currentVisualizer == nil)
		return nil;
	return [currentVisualizer visualizerName];
}

-(void) setCurrentVisualizerName:(NSString*)visualizerName
{
	[[NSUserDefaults standardUserDefaults] setObject:visualizerName forKey:kKCPrefSelectedVisualizer];
	id<KCVisualizer> new = [KCVisualizer visualizerWithName:visualizerName];
	[self setCurrentVisualizer:new];
}

-(id<KCVisualizer>) currentVisualizer
{
	return currentVisualizer;
}

-(void) setCurrentVisualizer:(id<KCVisualizer>)new
{
	id<KCVisualizer> old = currentVisualizer;
	if (new == nil || old == new)
	{
		return;
	}

	if (old != nil)
	{
		[old deactivateVisualizer:self];
	}

	currentVisualizer = new;
	[new showVisualizer:self];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"KCVisualizerChanged" object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:
		new, @"newVisualizer",
		old, @"oldVisualizer",
		nil]];
}

-(NSArray*) availableVisualizerNames
{
	NSArray* factories = [KCVisualizer availableVisualizerFactories];
	NSMutableArray* rval = [NSMutableArray array];
	int i = 0;
	for (i = 0; i < [factories count]; ++i)
	{
		id<KCVisualizerFactory> factory = [factories objectAtIndex:i];
		[rval addObject:[factory visualizerName]];
	}
	return rval;
}

-(BOOL) isCapturing
{
	return _isCapturing;
}

-(void) setIsCapturing:(BOOL)v
{
	_isCapturing = v;
	[statusItem setImage:(_isCapturing
		? [NSImage imageNamed:@"KeyCastrStatusItemActive"]
		: [NSImage imageNamed:@"KeyCastrStatusItemInactive"])
		];
	[statusShortcutItem setTitle:(_isCapturing
		? @"Stop Casting"
		: @"Start Casting")];
	[NSApp setApplicationIconImage:(_isCapturing
		? [NSImage imageNamed:@"KeyCastr"]
		: [NSImage imageNamed:@"KeyCastrInactive"])];
}

-(void) restartPanel:(NSAlert*)alert closedWithCode:(int)returnCode context:(void*)contextInfo
{
	if (returnCode == NSOKButton)
	{
		// manually flush preferences
		[[NSUserDefaults standardUserDefaults] synchronize];
	
		FSRef fsRef;
		FSPathMakeRef( (const UInt8 *)[[[NSBundle mainBundle] bundlePath] fileSystemRepresentation], &fsRef, NULL );

		LSApplicationParameters appParams;
		appParams.version = 0;
		appParams.flags = kLSLaunchNewInstance;
		appParams.application = &fsRef;
		appParams.asyncLaunchRefCon = NULL;
		appParams.environment = NULL;
		appParams.argv = NULL;
		appParams.initialEvent = NULL;
		ProcessSerialNumber psn;
		LSOpenApplication(
			&appParams,
			&psn );
		[NSApp terminate:self];
	}
}

-(void) changeIconPreference:(id)sender
{
	int newIconPref = [[NSUserDefaults standardUserDefaults] integerForKey:kKCPrefDisplayIcon];
	if ((newIconPref & 0x02) != (_startupIconPreference & 0x02) && !_displayedRestartAlertPanel)
	{
		_displayedRestartAlertPanel = YES;
		NSString* displayMessage = (_startupIconPreference & 0x02)
			? @"In order to hide the dock icon, KeyCastr must be restarted."
			: @"In order to show the dock icon, KeyCastr must be restarted.";
		NSAlert* a = [NSAlert alertWithMessageText:@"Restart required" defaultButton:@"Restart Now" alternateButton:@"Restart Later" otherButton:nil informativeTextWithFormat:@"%@", displayMessage];
		[a beginSheetModalForWindow:preferencesWindow modalDelegate:self didEndSelector:@selector(restartPanel:closedWithCode:context:) contextInfo:nil];
	}
	
	if (newIconPref & 0x01)
		[self createStatusItem];
	else
	{
		if (_startupIconPreference & 0x02)
			[self deleteStatusItem];
		else
		{
			// On startup, we did not have an icon in the dock.
			// Don't remove the menu bar item, because if we did,
			// KeyCastr would be inaccessible.
		}
	}
	
	NSTask* task = [NSTask launchedTaskWithLaunchPath:@"/usr/bin/defaults" arguments:[NSArray arrayWithObjects:
		@"write",
		[NSString stringWithFormat:@"%@/Contents/Info", [[NSBundle mainBundle] bundlePath]],
		@"LSUIElement",
		((newIconPref & 0x02)
			? @"0"
			: @"1"),
		nil]];
	[task waitUntilExit];
}

#pragma mark -
#pragma mark SRRecorderDelegate methods

-(void) shortcutRecorder:(SRRecorderControl*)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo
{
	[self changeKeyComboTo:newKeyCombo];
	[[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&newKeyCombo length:sizeof(newKeyCombo)] forKey:kKCPrefCapturingHotKey];
}

@end
