//
//  SRKeyEquivalentModifierMaskTransformer.h
//  ShortcutRecorder
//
//  Copyright 2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors to this file:
//      Ilya Kulakov

#import <Foundation/Foundation.h>


/*!
    Transform dictionary representation of shortcut into string suitable
    for -setKeyEquivalentModifierMask: of NSButton and NSMenuItem.
 */
@interface SRKeyEquivalentModifierMaskTransformer : NSValueTransformer

@end
