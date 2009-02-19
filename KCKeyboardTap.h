//
//  KCKeyboardTap.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KCKeystroke.h"

@class KCKeyboardTap;

@protocol KCKeyboardTapDelegate

-(void) keyboardTap:(KCKeyboardTap*)keyboardTap noteKeystroke:(KCKeystroke*)keystroke;
-(void) keyboardTap:(KCKeyboardTap*)keyboardTap noteFlagsChanged:(uint32_t)newFlags;

@end

@interface KCKeyboardTap : NSObject
{
	id _delegate;
}

+(KCKeyboardTap*) sharedKeyboardTap;

-(void) noteKeyEvent:(KCKeystroke*)keystroke;
-(void) noteFlagsChanged:(uint32_t)newFlags;

-(void) addObserver:(id)recipient selector:(SEL)aSelector;
-(void) removeObserver:(id)recipient;

-(void) setDelegate:(id)delegate;
-(id) delegate;

@end
