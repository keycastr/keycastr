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


#import <XCTest/XCTest.h>
#import <KCVisualizer/KCUserDefaultsMigration.h>

@interface KCUserDefaultsMigrationTests : XCTestCase

@end

@implementation KCUserDefaultsMigrationTests

- (void)test_migratingUserDefaults {
    NSArray *colorKeyNames = [KCUserDefaultsMigration colorKeyNames];
    NSUserDefaults *exampleDefaults = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass([self class])];
    [exampleDefaults setObject:[NSArchiver archivedDataWithRootObject:[NSColor colorWithCalibratedWhite:0 alpha:0.8]] forKey:colorKeyNames.firstObject];
    
    NSData *data = [exampleDefaults dataForKey:colorKeyNames.firstObject];
    NSColor *color = [NSUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertEqualWithAccuracy(0.8, color.alphaComponent, 0.01);
    
    [KCUserDefaultsMigration performMigration:exampleDefaults];
    
    data = [exampleDefaults dataForKey:colorKeyNames.firstObject];
    color = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    XCTAssertNotNil(color);
    XCTAssertEqualWithAccuracy(0.8, color.alphaComponent, 0.01);
}

@end
