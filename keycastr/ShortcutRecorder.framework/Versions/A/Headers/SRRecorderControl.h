//
//  SRRecorderControl.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import <Cocoa/Cocoa.h>
#import "SRRecorderCell.h"

@interface SRRecorderControl : NSControl
{
	IBOutlet id delegate;
}

#pragma mark *** Aesthetics ***
- (BOOL)animates;
- (void)setAnimates:(BOOL)an;
- (SRRecorderStyle)style;
- (void)setStyle:(SRRecorderStyle)nStyle;

#pragma mark *** Delegate ***
- (id)delegate;
- (void)setDelegate:(id)aDelegate;

#pragma mark *** Key Combination Control ***

- (unsigned int)allowedFlags;
- (void)setAllowedFlags:(unsigned int)flags;

- (BOOL)allowsKeyOnly;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;
- (BOOL)escapeKeysRecord;

- (BOOL)canCaptureGlobalHotKeys;
- (void)setCanCaptureGlobalHotKeys:(BOOL)inState;

- (unsigned int)requiredFlags;
- (void)setRequiredFlags:(unsigned int)flags;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)aKeyCombo;
- (void)clearKeyCombo;

- (NSString *)keyChars;
- (NSString *)keyCharsIgnoringModifiers;

#pragma mark *** Deprecated ***

- (NSString *)autosaveName SR_DEPRECATED_ATTRIBUTE;
- (void)setAutosaveName:(NSString *)aName SR_DEPRECATED_ATTRIBUTE;

#pragma mark -

#pragma mark IB3 tomfoolery

- (void)forIBuse__nilOutDeprecatedAutosaveName:(id)sender;
- (BOOL)forIBuse__hasDeprecatedAutosaveName;

#pragma mark -

// Returns the displayed key combination if set
- (NSString *)keyComboString;

#pragma mark *** Conversion Methods ***

- (unsigned int)cocoaToCarbonFlags:(unsigned int)cocoaFlags;
- (unsigned int)carbonToCocoaFlags:(unsigned int)carbonFlags;

@end

// Delegate Methods
@interface NSObject (SRRecorderDelegate)
- (BOOL)shortcutRecorder:(SRRecorderControl *)aRecorder isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason;
- (void)shortcutRecorder:(SRRecorderControl *)aRecorder keyComboDidChange:(KeyCombo)newKeyCombo;
@end
