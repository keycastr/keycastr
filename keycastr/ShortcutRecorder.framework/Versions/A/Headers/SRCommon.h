//
//  SRCommon.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Andy Kim
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


/*!
    Mask representing subset of Cocoa modifier flags suitable for shortcuts.
 */
static const NSEventModifierFlags SRCocoaModifierFlagsMask = NSCommandKeyMask | NSAlternateKeyMask | NSShiftKeyMask | NSControlKeyMask;

/*!
    Mask representing subset of Carbon modifier flags suitable for shortcuts.
 */
static const NSUInteger SRCarbonModifierFlagsMask = cmdKey | optionKey | shiftKey | controlKey;


/*!
    Converts carbon modifier flags to cocoa.
 */
FOUNDATION_STATIC_INLINE NSEventModifierFlags SRCarbonToCocoaFlags(UInt32 aCarbonFlags)
{
    NSEventModifierFlags cocoaFlags = 0;

    if (aCarbonFlags & cmdKey)
        cocoaFlags |= NSCommandKeyMask;

    if (aCarbonFlags & optionKey)
        cocoaFlags |= NSAlternateKeyMask;

    if (aCarbonFlags & controlKey)
        cocoaFlags |= NSControlKeyMask;

    if (aCarbonFlags & shiftKey)
        cocoaFlags |= NSShiftKeyMask;

    return cocoaFlags;
}

/*!
    Converts cocoa modifier flags to carbon.
 */
FOUNDATION_STATIC_INLINE UInt32 SRCocoaToCarbonFlags(NSEventModifierFlags aCocoaFlags)
{
    UInt32 carbonFlags = 0;

    if (aCocoaFlags & NSCommandKeyMask)
        carbonFlags |= cmdKey;

    if (aCocoaFlags & NSAlternateKeyMask)
        carbonFlags |= optionKey;

    if (aCocoaFlags & NSControlKeyMask)
        carbonFlags |= controlKey;

    if (aCocoaFlags & NSShiftKeyMask)
        carbonFlags |= shiftKey;

    return carbonFlags;
}


/*!
    Return Bundle where resources can be found.

    @discussion Throws NSInternalInconsistencyException if bundle cannot be found.
*/
NSBundle *SRBundle();


/*!
    Convenient method to get localized string from the framework bundle.
 */
NSString *SRLoc(NSString *aKey);


/*!
    Convenient method to get image from the framework bundle.
 */
NSImage *SRImage(NSString *anImageName);

/*!
    Returns string representation of shortcut with modifier flags replaced with their localized
    readable equivalents (e.g. ? -> Option).
 */
NSString *SRReadableStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode);

/*!
    Returns string representation of shortcut with modifier flags replaced with their localized
    readable equivalents (e.g. ? -> Option) and ASCII character for key code.
 */
NSString *SRReadableASCIIStringForCocoaModifierFlagsAndKeyCode(NSEventModifierFlags aModifierFlags, unsigned short aKeyCode);

/*!
    Determines if given key code with flags is equal to key equivalent and flags
    (usually taken from NSButton or NSMenu).

    @discussion On Mac OS X some key combinations can have "alternates". E.g. option-A can be represented both as option-A and as Œ.
*/
BOOL SRKeyCodeWithFlagsEqualToKeyEquivalentWithFlags(unsigned short aKeyCode,
                                                     NSEventModifierFlags aKeyCodeFlags,
                                                     NSString *aKeyEquivalent,
                                                     NSEventModifierFlags aKeyEquivalentModifierFlags);
