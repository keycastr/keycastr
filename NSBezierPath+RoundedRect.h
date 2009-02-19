//
//  NSBezierPathRoundedRect.h
//  KeyCastr
//
//  Created by Stephen Deken on 10/11/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBezierPath (RoundedRect)

-(void) appendRoundedRect:(NSRect)rect radius:(float)r;

@end
