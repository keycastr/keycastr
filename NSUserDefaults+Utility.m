//
//  NSUserDefaultsUtility.m
//  Zugzwang
//
//  Created by Stephen Deken on 9/6/06.
//  Copyright 2006 Stephen Deken. All rights reserved.
//

#import "NSUserDefaults+Utility.h"

@implementation NSUserDefaults (Utility)

-(void) setColor:(NSColor*)aColor forKey:(NSString*)aKey
{
    NSData *theData = [NSArchiver archivedDataWithRootObject:aColor];
    [self setObject:theData forKey:aKey];
}

-(NSColor*) colorForKey:(NSString*)aKey
{
    NSColor *theColor=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
        theColor=(NSColor *)[NSUnarchiver unarchiveObjectWithData:theData];
    return theColor;
}

-(void) setImage:(NSImage*)anImage forKey:(NSString*)aKey
{
    NSData *theData = [NSArchiver archivedDataWithRootObject:anImage];
    [self setObject:theData forKey:aKey];
}

-(NSImage*) imageForKey:(NSString*)aKey
{
    NSImage *theImage=nil;
    NSData *theData=[self dataForKey:aKey];
    if (theData != nil)
        theImage=(NSImage*)[NSUnarchiver unarchiveObjectWithData:theData];
    return theImage;
}

@end
