//    Copyright (c) 2021 Andrew Kitchen
//    All rights reserved.
//
//    Redistribution and use in source and binary forms, with or without modification,
//    are permitted provided that the following conditions are met:
//
//    *    Redistributions of source code must retain the above copyright notice, this
//         list of conditions and the following disclaimer.
//    *    Redistributions in binary form must reproduce the above copyright notice,
//         this list of conditions and the following disclaimer in the documentation
//         and/or other materials provided with the distribution.
//    *    Neither the name KeyCastr nor the names of its contributors may be used to
//         endorse or promote products derived from this software without specific
//         prior written permission.
//
//    THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//    AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//    WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//    IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//    INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//    BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//    LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//    OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//    ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import <Foundation/Foundation.h>


@interface KCKeycastrEvent : NSObject

@property (nonatomic, readonly) NSEventType type;
@property (nonatomic, readonly) NSEventModifierFlags modifierFlags;

/// An event is a command if it includes the Control or Command key; Option and Shift are only considered modifiers.
@property (nonatomic, readonly) BOOL isCommand;

/// Indicates whether a Keystroke has any of the Control, Command, Option or Shift modifiers applied.
@property (nonatomic, readonly) BOOL isModified;

+ (instancetype)eventWithNSEvent:(NSEvent *)event;
- (instancetype)initWithNSEvent:(NSEvent *)event NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;

- (NSString *)convertToString;

@end
