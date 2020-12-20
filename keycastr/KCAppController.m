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

typedef struct _KeyCombo {
    unsigned int flags; // 0 for no flags
    signed short code; // -1 for no code
} KeyCombo;

static NSString* kKCPrefCapturingHotKey = @"capturingHotKey";
static NSString* kKCPrefVisibleAtLaunch = @"alwaysShowPrefs";
static NSString* kKCPrefDisplayIcon = @"displayIcon";
static NSString* kKCPrefSelectedVisualizer = @"selectedVisualizer";
static NSString* kKCSupplementalAlertText = @"\n\nPlease check the box next to KeyCastr in the Input Monitoring menu within the Security & Privacy System Preferences pane. This will grant KeyCastr access to the Accessibility API in order to broadcast your keyboard inputs.\n\nIf your version of macOS doesn't have an Input Monitoring menu or if KeyCastr isn't listed, please add KeyCastr to the Accessibility menu instead. If KeyCastr is already listed under the Accessibility menu, please remove it and try again.\n";

static NSInteger kKCPrefDisplayIconInMenuBar = 0x01;
static NSInteger kKCPrefDisplayIconInDock = 0x02;

@interface KCAppController ()<KCKeyboardTapDelegate>

@property NSInteger prefDisplayIcon;
@property BOOL showInDock;
@property BOOL showInMenuBar;

@property (nonatomic, assign) KeyCombo toggleKeyCombo;

@end

@implementation KCAppController

#pragma mark -
#pragma mark Startup Procedures

-(id) init
{
	if (!(self = [super init]))
		return nil;

    keyboardTap = [KCKeyboardTap new];
    keyboardTap.delegate = self;

    [self _setupDefaults];
    [self registerVisualizers];

    [NSColor setIgnoresAlpha:NO];

    return self;
}

- (void)dealloc {
    [keyboardTap release];
    [statusItem release];
    [currentVisualizer release];
    [super dealloc];
}

- (void)awakeFromNib {
    [self setIsCapturing:NO];
    
    // Set current visualizer from user preferences
    [self setCurrentVisualizerName:[[NSUserDefaults standardUserDefaults] objectForKey:kKCPrefSelectedVisualizer]];

    // Bootstrap key capturing hotkey from preferences
    KeyCombo toggleShortcutKey;
    toggleShortcutKey.code = -1;
    toggleShortcutKey.flags = 0;

    NSData *toggleShortcutKeyData = [[NSUserDefaults standardUserDefaults] dataForKey:kKCPrefCapturingHotKey];
    if (toggleShortcutKeyData != nil) {
        [toggleShortcutKeyData getBytes:&toggleShortcutKey length:sizeof(toggleShortcutKey)];
    }

    [self changeKeyComboTo:toggleShortcutKey];
    [shortcutRecorder setObjectValue:@{SRShortcutKeyCode: @(toggleShortcutKey.code),
            SRShortcutModifierFlagsKey: @(toggleShortcutKey.flags)}];

    [prefsWindowController nudge];

    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kKCPrefDisplayIcon
                                               options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                                               context:nil];
}

- (void)applicationWillFinishLaunching:(NSNotification *)notification {

    [NSApp activateIgnoringOtherApps:YES];

    if (![self installTap]) {
        return;
    }

    [self setIsCapturing:YES];

    // Show the preferences window if desired
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kKCPrefVisibleAtLaunch]) {
        [preferencesWindow center];
        [preferencesWindow makeKeyAndOrderFront:self];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    [keyboardTap removeTap];
}

- (void)openPrefsPane:(id)sender {
    NSString *text = @"tell application \"System Preferences\" \n reveal anchor \"Privacy_Accessibility\" of pane id \"com.apple.preference.security\" \n activate \n end tell";
    NSAppleScript *script = [[NSAppleScript alloc] initWithSource:text];
    [script executeAndReturnError:nil];
    [script release];
}

- (void)displayPermissionsAlertWithError:(NSError *)error {
    NSAlert *alert = [[NSAlert new] autorelease];
    [alert addButtonWithTitle:@"Close"];
    [alert addButtonWithTitle:@"Open System Preferences"];
    alert.messageText = @"Additional Permissions Required";
    alert.informativeText = [error.localizedDescription stringByAppendingString:kKCSupplementalAlertText];
    alert.alertStyle = NSCriticalAlertStyle;

    switch ([alert runModal]) {
        case NSAlertFirstButtonReturn:
            [NSApp terminate:nil];
            break;
        case NSAlertSecondButtonReturn: {
            [self openPrefsPane:nil];
            [NSApp terminate:nil];
        }
            break;
    }
}

- (BOOL)installTap {
    NSError *error = nil;
    if (![keyboardTap installTapWithError:&error]) {
        // Only display a custom error message if we're running on macOS < 10.15
        NSOperatingSystemVersion minimumSupportedOSVersion = { .majorVersion = 10, .minorVersion = 15, .patchVersion = 0 };
        BOOL hasOwnPermissionsAlert = [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minimumSupportedOSVersion];

        if (!hasOwnPermissionsAlert) {
            [self displayPermissionsAlertWithError:error];
        }
        return NO;
    }
    return YES;
}

-(void) _mapOldPreference:(NSString*)old toNewPreference:(NSString*)new
{
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud setObject:[ud objectForKey:old] forKey:new];
	[ud removeObjectForKey:old];
}

-(void) _setupDefaults
{
	// Set up user-defaults defaults
	KeyCombo keyCombo;
	keyCombo.code = 40;
	keyCombo.flags = NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask;
	NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
	[ud synchronize];

	[ud registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
		[NSNumber numberWithInt:3], kKCPrefDisplayIcon,
		@"Default", kKCPrefSelectedVisualizer,
		[NSNumber numberWithBool:YES], kKCPrefVisibleAtLaunch,
		[NSData dataWithBytes:&keyCombo length:sizeof(keyCombo)], kKCPrefCapturingHotKey,

		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0 alpha:0.8]], @"default.bezelColor",
		[NSNumber numberWithFloat:2.0], @"default.fadeDelay",
		[NSNumber numberWithFloat:0.2], @"default.fadeDuration",
		[NSNumber numberWithFloat:16.0], @"default.fontSize",
		[NSNumber numberWithFloat:0.5], @"default.keystrokeDelay",
		[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:1 alpha:1]], @"default.textColor",
		nil]];

	if ([ud objectForKey:@"fontSize"] != nil)
	{
		// Clean up old 0.7.x defaults
		[self _mapOldPreference:@"bezelColor" toNewPreference:@"default.bezelColor"];
		[self _mapOldPreference:@"fadeDelay" toNewPreference:@"default.fadeDelay"];
		[self _mapOldPreference:@"fontSize" toNewPreference:@"default.fontSize"];
		[self _mapOldPreference:@"keystrokeDelay" toNewPreference:@"default.keystrokeDelay"];
		[self _mapOldPreference:@"textColor" toNewPreference:@"default.textColor"];
		[self _mapOldPreference:@"onlyCommandKeys" toNewPreference:@"default.commandKeysOnly"];
		NSDictionary* oldKey = [ud objectForKey:@"ShortcutRecorder toggleCapture"];
		if (oldKey != nil)
		{
			keyCombo.code = [[oldKey objectForKey:@"keyCode"] intValue];
			keyCombo.flags = [[oldKey objectForKey:@"modifierFlags"] intValue];
			[ud setObject:[NSData dataWithBytes:&keyCombo length:sizeof(keyCombo)] forKey:kKCPrefCapturingHotKey];
			[ud removeObjectForKey:@"ShortcutRecorder toggleCapture"];
		}
		[ud removeObjectForKey:@"launchedOnce"];
	}
	[ud synchronize];
}

-(void) keyboardTap:(KCKeyboardTap*)tap noteKeystroke:(KCKeystroke*)keystroke
{
	if ([keystroke keyCode] == self.toggleKeyCombo.code && ([keystroke modifiers] & (NSControlKeyMask | NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)) == (self.toggleKeyCombo.flags & (NSControlKeyMask | NSCommandKeyMask | NSShiftKeyMask | NSAlternateKeyMask)))
	{
        [self toggleRecording:self];
		return;
	}
	
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
    [factory autorelease];
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

-(void) changeKeyComboTo:(KeyCombo)keyCombo
{
    self.toggleKeyCombo = keyCombo;
    if (keyCombo.code != -1)
    {
        SRKeyCodeTransformer* xformer = [SRKeyCodeTransformer sharedTransformer];
        [statusShortcutItem setKeyEquivalent:[xformer transformedValue:@(keyCombo.code)]];
        [statusShortcutItem setKeyEquivalentModifierMask:keyCombo.flags];
        [dockShortcutItem setKeyEquivalent:[xformer transformedValue:@(keyCombo.code)]];
        [dockShortcutItem setKeyEquivalentModifierMask:keyCombo.flags];
    }
    else
    {
        [statusShortcutItem setKeyEquivalent:@""];
        [dockShortcutItem setKeyEquivalent:@""];
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
	[self toggleRecording:self];
}

-(void) pretendToDoSomethingImportant:(id)sender
{
	[self performSelector:@selector(stopPretending:) withObject:nil afterDelay:0.1];
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

- (void)setCurrentVisualizer:(id <KCVisualizer>)newVisualizer {
    if (newVisualizer == nil || currentVisualizer == newVisualizer) {
        return;
    }
    
    id <KCVisualizer> oldVisualizer = [currentVisualizer autorelease];

    if (oldVisualizer != nil) {
        [oldVisualizer deactivateVisualizer:self];
    }

    currentVisualizer = [newVisualizer retain];
    [newVisualizer showVisualizer:self];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObjectsAndKeys:newVisualizer, @"newVisualizer", oldVisualizer, @"oldVisualizer", nil];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"KCVisualizerChanged" object:self userInfo:userInfo];
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

-(void) setIsCapturing:(BOOL)capture
{
    if (capture && !keyboardTap.tapInstalled) {
        return;
    }

	_isCapturing = capture;
	[statusItem setImage:(_isCapturing
		? [NSImage imageNamed:@"KeyCastrStatusItemActive"]
		: [NSImage imageNamed:@"KeyCastrStatusItemInactive"])
		];
	[statusShortcutItem setTitle:(_isCapturing
		? @"Stop Casting"
		: @"Start Casting")];
	[dockShortcutItem setTitle:(_isCapturing
		? @"Stop Casting"
		: @"Start Casting")];
	[NSApp setApplicationIconImage:(_isCapturing
		? [NSImage imageNamed:@"KeyCastr"]
		: [NSImage imageNamed:@"KeyCastrInactive"])];
}

-(void) restartPanel:(NSAlert*)alert closedWithCode:(NSModalResponse)returnCode
{
	if (returnCode == NSAlertFirstButtonReturn)
	{
		[[NSUserDefaults standardUserDefaults] synchronize];

        NSURL *bundleURL = [[NSBundle mainBundle] bundleURL];
        [[NSWorkspace sharedWorkspace] launchApplicationAtURL:bundleURL
                                                      options:NSWorkspaceLaunchNewInstance
                                                configuration:@{}
                                                        error:NULL];
		[NSApp terminate:self];
	}
}

-(void) changeIconPreference:(id)sender
{
    // sent from the UI.  Ignore until we can update the UI to remove this event.
}

#pragma mark -
#pragma mark Observers

-(void) prefDisplayIconUpdatedTo:(NSInteger)prefDisplayIcon {
    // if the pref is set such that the icon is hidden in both the menu bar and the dock,
    // show the icon in the dock regardless of the user's preference.
    if (0 == (prefDisplayIcon & (kKCPrefDisplayIconInMenuBar | kKCPrefDisplayIconInDock))) {
        prefDisplayIcon = prefDisplayIcon | kKCPrefDisplayIconInDock;
    }
    
    ProcessSerialNumber psn = { 0, kCurrentProcess };
    if (prefDisplayIcon & kKCPrefDisplayIconInDock) {
        // show dock icon
        TransformProcessType(&psn, kProcessTransformToForegroundApplication);
    }
    else {
        // hide dock icon
        preferencesWindow.canHide = NO;
        TransformProcessType(&psn, kProcessTransformToUIElementApplication);
    }

    if (prefDisplayIcon & kKCPrefDisplayIconInMenuBar) {
        // show icon in menu bar
        [self createStatusItem];
    }
    else {
        // hide icon in menu bar
        [self deleteStatusItem];
    }
}

-(void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:kKCPrefDisplayIcon]) {
        [self prefDisplayIconUpdatedTo:[[change objectForKey:NSKeyValueChangeNewKey] integerValue]];
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark -
#pragma mark Properties

-(NSInteger) prefDisplayIcon {
    return [NSUserDefaults.standardUserDefaults integerForKey:kKCPrefDisplayIcon];
}

-(void) setPrefDisplayIcon:(NSInteger)prefDisplayIcon {
    [NSUserDefaults.standardUserDefaults setInteger:prefDisplayIcon forKey:kKCPrefDisplayIcon];
}

-(BOOL) showInDock {
    return (self.prefDisplayIcon & kKCPrefDisplayIconInDock) == kKCPrefDisplayIconInDock;
}

-(void) setShowInDock:(BOOL)showInDock {
    self.prefDisplayIcon = (self.prefDisplayIcon & ~kKCPrefDisplayIconInDock) | (showInDock ? kKCPrefDisplayIconInDock : 0);
}

-(BOOL) showInMenuBar {
    return (self.prefDisplayIcon & kKCPrefDisplayIconInMenuBar) == kKCPrefDisplayIconInMenuBar;
}

-(void) setShowInMenuBar:(BOOL)showInMenuBar {
    self.prefDisplayIcon = (self.prefDisplayIcon & ~kKCPrefDisplayIconInMenuBar) | (showInMenuBar ? kKCPrefDisplayIconInMenuBar : 0);
}

#pragma mark -
#pragma mark SRRecorderControlDelegate methods

- (void)shortcutRecorderDidEndRecording:(SRRecorderControl *)aRecorder;
{
    NSDictionary *toggleShortcut = aRecorder.objectValue;
    KeyCombo newKeyCombo;
    newKeyCombo.code = [toggleShortcut[SRShortcutKeyCode] shortValue];
    newKeyCombo.flags = [toggleShortcut[SRShortcutModifierFlagsKey] unsignedIntValue];

    [self changeKeyComboTo:newKeyCombo];
    [[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&newKeyCombo length:sizeof(newKeyCombo)] forKey:kKCPrefCapturingHotKey];
}

@end

// This class needs to exist for compatibility with the legacy MainMenu.nib
@interface SRRecorderCell : NSActionCell
@end

@implementation SRRecorderCell
@end
