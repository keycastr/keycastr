//
//  SRRecorderCell.h
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
#import "SRCommon.h"

#define SRMinWidth 50
#define SRMaxHeight 22

#define SRTransitionFPS 30.0
#define SRTransitionDuration 0.35
//#define SRTransitionDuration 2.35
#define SRTransitionFrames (SRTransitionFPS*SRTransitionDuration)
#define SRAnimationAxisIsY YES
#define ShortcutRecorderNewStyleDrawing

#define SRAnimationOffsetRect(X,Y)	(SRAnimationAxisIsY ? NSOffsetRect(X,0.0,-NSHeight(Y)) : NSOffsetRect(X,NSWidth(Y),0.0))

@class SRRecorderControl, CTGradient, SRValidator;

enum SRRecorderStyle {
    SRGradientBorderStyle = 0,
    SRGreyStyle = 1
};
typedef enum SRRecorderStyle SRRecorderStyle;

@interface SRRecorderCell : NSActionCell <NSCoding>
{	
	CTGradient          *recordingGradient;
	NSString            *autosaveName;
	
	BOOL                isRecording;
	BOOL                mouseInsideTrackingArea;
	BOOL                mouseDown;
	
	SRRecorderStyle		style;
	
	BOOL				isAnimating;
	double				transitionProgress;
	BOOL				isAnimatingNow;
	BOOL				isAnimatingTowardsRecording;
	BOOL				comboJustChanged;
	
	NSTrackingRectTag   removeTrackingRectTag;
	NSTrackingRectTag   snapbackTrackingRectTag;
	
	KeyCombo            keyCombo;
	BOOL				hasKeyChars;
	NSString		    *keyChars;
	NSString		    *keyCharsIgnoringModifiers;
	
	unsigned int        allowedFlags;
	unsigned int        requiredFlags;
	unsigned int        recordingFlags;
	
	BOOL				allowsKeyOnly;
	BOOL				escapeKeysRecord;
	
	NSSet               *cancelCharacterSet;
	
    SRValidator         *validator;
    
	IBOutlet id         delegate;
	BOOL				globalHotKeys;
	void				*hotKeyModeToken;
}

- (void)resetTrackingRects;

#pragma mark *** Aesthetics ***

+ (BOOL)styleSupportsAnimation:(SRRecorderStyle)style;

- (BOOL)animates;
- (void)setAnimates:(BOOL)an;
- (SRRecorderStyle)style;
- (void)setStyle:(SRRecorderStyle)nStyle;

#pragma mark *** Delegate ***

- (id)delegate;
- (void)setDelegate:(id)aDelegate;

#pragma mark *** Responder Control ***

- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;

#pragma mark *** Key Combination Control ***

- (BOOL)performKeyEquivalent:(NSEvent *)theEvent;
- (void)flagsChanged:(NSEvent *)theEvent;

- (unsigned int)allowedFlags;
- (void)setAllowedFlags:(unsigned int)flags;

- (unsigned int)requiredFlags;
- (void)setRequiredFlags:(unsigned int)flags;

- (BOOL)allowsKeyOnly;
- (void)setAllowsKeyOnly:(BOOL)nAllowsKeyOnly escapeKeysRecord:(BOOL)nEscapeKeysRecord;
- (BOOL)escapeKeysRecord;

- (BOOL)canCaptureGlobalHotKeys;
- (void)setCanCaptureGlobalHotKeys:(BOOL)inState;

- (KeyCombo)keyCombo;
- (void)setKeyCombo:(KeyCombo)aKeyCombo;
- (void)clearKeyCombo;

#pragma mark *** Autosave Control ***

- (NSString *)autosaveName;
- (void)setAutosaveName:(NSString *)aName;

// Returns the displayed key combination if set
- (NSString *)keyComboString;

- (NSString *)keyChars;
- (NSString *)keyCharsIgnoringModifiers;

@end

// Delegate Methods
@interface NSObject (SRRecorderCellDelegate)
- (BOOL)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell isKeyCode:(signed short)keyCode andFlagsTaken:(unsigned int)flags reason:(NSString **)aReason;
- (void)shortcutRecorderCell:(SRRecorderCell *)aRecorderCell keyComboDidChange:(KeyCombo)newCombo;
@end
