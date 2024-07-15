//  Copyright (c) 2024 Andrew Kitchen
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


#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface KCUserDefaultsMigration : NSObject

///
/// Migrates the default visualizer's NSColor data stored in NSUserDefaults from the deprecated NSArchiver/NSUnarchiver format to the format used by the NSKeyedArchiver/NSKeyedUnarchiver. Also removes a default which was written to but otherwise unused by the Svelte visualizer.
///
/// This method should be the only place in the codebase that references the deprecated NSArchiver/NSUnarchiver classes. It can be removed in any release after the next release after a reasonable period of time.
///
/// TODO: A new migration may be needed for keys with namespacing, e.g. default.bezelColor. This namespacing breaks KVO, although it seems that KVC works OK
///
+ (void)performMigration:(NSUserDefaults *)userDefaults;
+ (NSArray *)colorKeyNames;

@end

NS_ASSUME_NONNULL_END
