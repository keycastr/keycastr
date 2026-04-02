//  Copyright (c) 2026 Daniel Costa
//
//  All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  *    Redistributions of source code must retain the above copyright notice, this
//      list of conditions and the following disclaimer.
//  *    Redistributions in binary form must reproduce the above copyright notice,
//      this list of conditions and the following disclaimer in the documentation
//      and/or other materials provided with the distribution.
//  *    Neither the name KeyCastr nor the names of its contributors may be used to
//      endorse or promote products derived from this software without specific
//      prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
//  WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.
//  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
//  INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
//  BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
//  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
//  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
//  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
//  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

#import "KCDisplayMode.h"

static NSString* kKCDisplayModeCommand = @"display.command";
static NSString* kKCDisplayModeOption = @"display.option";
static NSString* kKCDisplayModeControl = @"display.control";
static NSString* kKCDisplayModeShift = @"display.shift";
static NSString* kKCDisplayModeFunction = @"display.function";
static NSString* kKCDisplayModeNonModifier = @"display.nonmodifier";

@implementation KCDisplayMode

+ (BOOL)command {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeCommand];
}

+ (BOOL)option {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeOption];
}

+ (BOOL)control {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeControl];
}

+ (BOOL)shift {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeShift];
}

+ (BOOL)function {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeFunction];
}

+ (BOOL)nonModifier {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kKCDisplayModeNonModifier];
}

// Preferences
+ (NSDictionary *)defaults {
    return @{
        kKCDisplayModeCommand:     @YES,
        kKCDisplayModeOption:      @YES,
        kKCDisplayModeControl:     @YES,
        kKCDisplayModeShift:       @YES,
        kKCDisplayModeFunction:    @YES,
        kKCDisplayModeNonModifier: @NO
    };
}

@end

@implementation KCAvailableDisplayMode

+ (KCAvailableDisplayMode *)sharedInstance {
    static KCAvailableDisplayMode *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[KCAvailableDisplayMode alloc] init];
    });
    return instance;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"availableModes"]) {
        return [NSSet set];
    }
    return [NSSet setWithObject:@"availableModes"];
}

- (KCAvailableDisplayMode *)displayModes {
    return [KCAvailableDisplayMode sharedInstance];
}

- (BOOL)isCommandAvailable {
    return self.availableModes & KCDisplayModeTypeCommand;
}

- (BOOL)isOptionAvailable {
    return self.availableModes & KCDisplayModeTypeOption;
}

- (BOOL)isControlAvailable {
    return self.availableModes & KCDisplayModeTypeControl;
}

- (BOOL)isShiftAvailable {
    return self.availableModes & KCDisplayModeTypeShift;
}

- (BOOL)isFunctionAvailable {
    return self.availableModes & KCDisplayModeTypeFunction;
}

- (BOOL)isNonModifierAvailable {
    return self.availableModes & KCDisplayModeTypeNonModifier;
}

@end
