//
//  NSUserDefaultsUtility.h
//  Zugzwang
//
//  Created by Stephen Deken on 9/6/06.
//  Copyright 2006 Stephen Deken. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSUserDefaults (Utility)

-(void) setColor:(NSColor*)aColor forKey:(NSString*)aKey;
-(NSColor*) colorForKey:(NSString*)aKey;

-(void) setImage:(NSImage*)anImage forKey:(NSString*)aKey;
-(NSImage*) imageForKey:(NSString*)aKey;


@end
