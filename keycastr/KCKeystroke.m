//	Copyright (c) 2009 Stephen Deken
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


#import "KCKeystroke.h"
#import "KCKeystrokeTransformer.h"

@implementation KCKeystroke

- (id)initWithKeyCode:(uint16_t)keyCode modifiers:(NSEventModifierFlags)modifiers characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers {
    if (!(self = [super init]))
        return nil;

    _keyCode = keyCode;
    _modifiers = modifiers;
    _characters = [characters copy];
    _charactersIgnoringModifiers = [charactersIgnoringModifiers copy];

    return self;
}

- (void)dealloc {
	[_charactersIgnoringModifiers release];
	_charactersIgnoringModifiers = nil;
    [_characters release];
    _characters = nil;
    [super dealloc];
}

- (BOOL)isCommand {
    return (_modifiers & (NSAlternateKeyMask | NSControlKeyMask | NSCommandKeyMask)) != 0;
}

- (BOOL)isLetter {
    unichar character = [self.characters characterAtIndex:0];
    return [[NSCharacterSet letterCharacterSet] characterIsMember:character];
}

- (BOOL)isAlphanumeric {
    unichar character = [self.characters characterAtIndex:0];
    NSCharacterSet *punctuationSet = [NSCharacterSet punctuationCharacterSet]; // [NSCharacterSet characterSetWithCharactersInString:@"`~!!!!!!!@#$%^&*()_+1234567890-=[]\{}|;':\",./<>?]"];
    NSCharacterSet *alphanumericSet = [NSCharacterSet alphanumericCharacterSet];
    return [alphanumericSet characterIsMember:character] || [punctuationSet characterIsMember:character];
}

- (NSString *)convertToString {
    return [[KCKeystrokeTransformer sharedTransformer] transformedValue:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<KCKeystroke: keyCode: %hu, modifiers: %lu, characters: %@, charactersIgnoringModifiers: %@>",
            _keyCode, (unsigned long)_modifiers, _characters, _charactersIgnoringModifiers];
}

@end
