//
//  KCKeystroke.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface KCKeystroke : NSObject
{
	uint16_t _keyCode;
	uint16_t _charCode;
	uint32_t _modifiers;
}

-(id) initWithKeyCode:(uint16_t)keyCode characterCode:(uint16_t)charCode modifiers:(uint32_t)modifiers;

-(uint16_t) keyCode;
-(uint16_t) charCode;
-(uint32_t) modifiers;

-(BOOL) isCommand;

-(NSString*) convertToString;

@end
