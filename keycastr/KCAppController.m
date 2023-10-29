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


#import <Quartz/Quartz.h>
#import <ShortcutRecorder/ShortcutRecorder.h>
#import "KCAppController.h"
#import "KCDefaultVisualizer.h"
#import "KCEventTap.h"
#import "KCKeystroke.h"
#import "KCMouseEventVisualizer.h"
#import "KCPrefsWindowController.h"

typedef struct _KeyCombo {
    unsigned int flags; // 0 for no flags
    signed short code; // -1 for no code
} KeyCombo;

static NSString* kKCPrefCapturingHotKey = @"capturingHotKey";
static NSString* kKCPrefVisibleAtLaunch = @"alwaysShowPrefs";
static NSString* kKCPrefDisplayIcon = @"displayIcon";
static NSString* kKCPrefSelectedVisualizer = @"selectedVisualizer";
static NSString* kKCSupplementalAlertText = @"\n\nPlease grant KeyCastr access to the Accessibility and/or Input Monitoring API in order to broadcast your keyboard inputs.\n\nWithin the System Preferences application, open the Security & Privacy preferences and add KeyCastr to the Accessibility and/or Input Monitoring list within the Privacy tab. If KeyCastr is already listed under the menus, please remove it and try again.\n";

static NSInteger kKCPrefDisplayIconInMenuBar = 0x01;
static NSInteger kKCPrefDisplayIconInDock = 0x02;

@interface KCAppController () <KCEventTapDelegate, KCMouseEventVisualizerDelegate>

@property (nonatomic, assign) NSInteger prefDisplayIcon;
@property (nonatomic, assign) BOOL showInDock;
@property (nonatomic, assign) BOOL showInMenuBar;
@property (nonatomic, assign) KeyCombo toggleKeyCombo;

@property (nonatomic, assign) IBOutlet NSMenu *statusMenu;
@property (nonatomic, assign) IBOutlet NSWindow *aboutWindow;
@property (nonatomic, assign) IBOutlet QCView   *aboutQCView;
@property (nonatomic, assign) IBOutlet NSWindow *preferencesWindow;
@property (nonatomic, assign) IBOutlet KCPrefsWindowController *prefsWindowController;
@property (nonatomic, assign) IBOutlet SRRecorderControl *shortcutRecorder;
@property (nonatomic, assign) IBOutlet NSMenuItem *statusShortcutItem;
@property (nonatomic, assign) IBOutlet NSMenuItem *dockShortcutItem;

@end

@implementation KCAppController {
    NSStatusItem *statusItem;
    KCEventTap *eventTap;
    id<KCVisualizer> currentVisualizer;
    KCMouseEventVisualizer *mouseEventVisualizer;

    BOOL _isCapturing;
}

@synthesize statusMenu, aboutWindow, preferencesWindow, prefsWindowController, shortcutRecorder, dockShortcutItem, statusShortcutItem;

#pragma mark -
#pragma mark Startup Procedures

- (id)init {
    if (!(self = [super init]))
        return nil;

    eventTap = [KCEventTap new];
    eventTap.delegate = self;

    [self _setupDefaults];
    [self registerVisualizers];

    mouseEventVisualizer = [KCMouseEventVisualizer new];
    mouseEventVisualizer.delegate = self;

    [NSColor setIgnoresAlpha:NO];

    return self;
}

- (void)dealloc {
    [eventTap release];
    [statusItem release];
    [currentVisualizer release];
    [mouseEventVisualizer release];

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
    SRShortcut *shortcut = [SRShortcut shortcutWithDictionary:@{SRShortcutKeyKeyCode: @(toggleShortcutKey.code),
                                                                SRShortcutKeyModifierFlags: @(toggleShortcutKey.flags)}];
    [shortcutRecorder setObjectValue:shortcut];

    [prefsWindowController nudge];
    [self updateAboutPanel];

    [[NSUserDefaults standardUserDefaults] addObserver:self
                                            forKeyPath:kKCPrefDisplayIcon
                                               options:(NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew)
                                               context:nil];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
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
    [eventTap removeTap];
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
    alert.alertStyle = NSAlertStyleCritical;

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
    if (![eventTap installTapWithError:&error]) {
        // Only display a custom error message if we're running on macOS < 10.15
        NSOperatingSystemVersion minVersion = { .majorVersion = 10, .minorVersion = 15, .patchVersion = 0 };
        BOOL supportsNewPermissionsAlert = [NSProcessInfo.processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [NSProcessInfo.processInfo isOperatingSystemAtLeastVersion:minVersion];

        if (!supportsNewPermissionsAlert) {
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
    keyCombo.flags = NSEventModifierFlagControl | NSEventModifierFlagOption | NSEventModifierFlagCommand;
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

- (void)eventTap:(KCEventTap *)tap noteKeystroke:(KCKeystroke *)keystroke
{
    if ([keystroke keyCode] == self.toggleKeyCombo.code && ([keystroke modifierFlags] & (NSEventModifierFlagControl | NSEventModifierFlagCommand | NSEventModifierFlagShift | NSEventModifierFlagOption)) == (self.toggleKeyCombo.flags & (NSEventModifierFlagControl | NSEventModifierFlagCommand | NSEventModifierFlagShift | NSEventModifierFlagOption)))
	{
        [self toggleRecording:self];
		return;
	}
	
    if (!_isCapturing) {
		return;
    }

    if (currentVisualizer != nil) {
		[currentVisualizer noteKeyEvent:keystroke];
    }
}

- (void)eventTap:(KCEventTap *)tap noteFlagsChanged:(NSEventModifierFlags)flags
{
    if (currentVisualizer != nil) {
		[currentVisualizer noteFlagsChanged:flags];
    }
}

- (void)eventTap:(KCEventTap *)eventTap noteMouseEvent:(KCMouseEvent *)mouseEvent
{
    // TODO: need to let mouseUp events through after isCapturing or mouse events are disabled, otherwise we can end up with a stuck visualizer animation
    if (!_isCapturing) {
        return;
    }

    [mouseEventVisualizer noteMouseEvent:mouseEvent];
}

- (void)mouseEventVisualizer:(KCMouseEventVisualizer *)visualizer didNoteMouseEvent:(KCMouseEvent *)mouseEvent
{
    [currentVisualizer noteMouseEvent:mouseEvent];
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

- (void)updateAboutPanel
{
    for (NSView *subview in aboutWindow.contentView.subviews) {
        if ([subview isKindOfClass:[NSTextField class]]) {
            NSTextField *textField = (NSTextField *)subview;
            NSString *prefix = @"Version ";
            if ([textField.stringValue rangeOfString:prefix].location == 0) {
                [textField setStringValue:[prefix stringByAppendingString:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"]]];
            }
        }
    }

    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"KeyCastrAbout" ofType:@"qtz"];
	[_aboutQCView loadCompositionFromFile:filePath];
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

- (NSArray *)availableMouseDisplayOptionNames {
    return mouseEventVisualizer.mouseDisplayOptionNames;
}

- (NSString *)currentMouseDisplayOptionName {
    return mouseEventVisualizer.currentMouseDisplayOptionName;
}

- (void)setCurrentMouseDisplayOptionName:(NSString *)displayOptionName {
    mouseEventVisualizer.currentMouseDisplayOptionName = displayOptionName;
}

-(void) setIsCapturing:(BOOL)capture
{
    if (capture && !eventTap.tapInstalled) {
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
    SRShortcut *toggleShortcut = aRecorder.objectValue;
    KeyCombo newKeyCombo;
    newKeyCombo.code = [toggleShortcut[SRShortcutKeyKeyCode] shortValue];
    newKeyCombo.flags = [toggleShortcut[SRShortcutKeyModifierFlags] unsignedIntValue];

    [self changeKeyComboTo:newKeyCombo];
    [[NSUserDefaults standardUserDefaults] setObject:[NSData dataWithBytes:&newKeyCombo length:sizeof(newKeyCombo)] forKey:kKCPrefCapturingHotKey];
}

@end
