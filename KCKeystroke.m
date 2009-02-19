//
//  KCKeystroke.m
//  KeyCastr
//
//  Created by Stephen Deken on 1/30/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KCKeystroke.h"
#import "KCKeystrokeTransformer.h"

@implementation KCKeystroke

-(id) initWithKeyCode:(uint16_t)keyCode characterCode:(uint16_t)charCode modifiers:(uint32_t)modifiers;
{
	if (![super init])
		return nil;

	_keyCode = keyCode;
	_charCode = charCode;
	_modifiers = modifiers;

	return self;
}

-(uint16_t) keyCode
{
	return _keyCode;
}

-(uint32_t) modifiers
{
	return _modifiers;
}

-(uint16_t) charCode
{
	return _charCode;
}

-(BOOL) isCommand
{
	return (_modifiers & (NSAlternateKeyMask | NSControlKeyMask | NSCommandKeyMask)) != 0;
}

-(NSString*) convertToString
{
	return [[KCKeystrokeTransformer sharedTransformer] transformedValue:self];
}

@end
