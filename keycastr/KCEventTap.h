//	Copyright (c) 2009 Stephen Deken
//	Copyright (c) 2020-2023 Andrew Kitchen
//
//	All rights reserved.
//
//	Redistribution and use in source and binary forms, with or without modification,
//	are permitted provided that the following conditions are met:
//
//	*	Redistributions of source code must retain the above copyright notice, this
//		list of conditions and the following disclaimer.
//	*	Redistributions in binary form must reproduce the above copyright notice,
//		this list of conditions and the following disclaimer in the documentation
//		and/or other materials provided with the distribution.
//	*	Neither the name KeyCastr nor the names of its contributors may be used to
//		endorse or promote products derived from this software without specific
//		prior written permission.
//
//	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//	AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//	BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//	DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//	LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//	OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//	ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


#import <Foundation/Foundation.h>

@class KCKeystroke, KCMouseEvent;
@protocol KCEventTapDelegate;

@interface KCEventTap : NSObject

@property (nonatomic, assign) id<KCEventTapDelegate> delegate;
@property (nonatomic, assign, readonly) BOOL tapInstalled;

- (BOOL)installTapWithError:(NSError **)error;
- (void)removeTap;

@end

@protocol KCEventTapDelegate <NSObject>

/// A Keystroke is a normal standalone key press, or a modified/command key sequence including the final key
- (void)eventTap:(KCEventTap *)tap noteKeystroke:(KCKeystroke *)keystroke;

/// Sent in response to the corresponding lower-level KeyUp events, for visualizers that are interested in them
- (void)eventTap:(KCEventTap *)tap noteKeyUp:(KCKeystroke *)keystroke;

/// Any of the mouse events KeyCastr listens for
- (void)eventTap:(KCEventTap *)tap noteMouseEvent:(KCMouseEvent *)mouseEvent;

/// Sent any time the currently-held combination of modifier keys changes
- (void)eventTap:(KCEventTap *)tap noteFlagsChanged:(NSEventModifierFlags)flags;

@end
