//
//  SRModifierFlagsTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


/*!
    Transforms mask of Cocoa modifier flags to string of unicode characters.
 */
@interface SRModifierFlagsTransformer : NSValueTransformer

- (instancetype)initWithPlainStrings:(BOOL)aUsesPlainStrings;

/*!
    Determines whether modifier flags are transformed to unicode characters or to plain strings.
 */
@property (readonly) BOOL usesPlainStrings;

/*!
     Returns the shared transformer.
 */
+ (instancetype)sharedTransformer;

/*!
     Returns the shared plain transformer.
 */
+ (instancetype)sharedPlainTransformer;

@end
