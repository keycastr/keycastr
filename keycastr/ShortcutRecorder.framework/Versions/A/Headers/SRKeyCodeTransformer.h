//
//  SRKeyCodeTransformer.h
//  ShortcutRecorder
//
//  Copyright 2006-2012 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick
//      Ilya Kulakov
//      Silvio Rizzi

#import <Cocoa/Cocoa.h>
#import <Carbon/Carbon.h>


/*!
    Transforms key code into unicode character or plain string.
 */
@interface SRKeyCodeTransformer : NSValueTransformer

/*!
    Returns initialized key code transformer.

    @param      aUsesASCII Determines whether transformer uses only ASCII capable keyboard input source.

    @param      aUsesPlainStrings Determines whether key codes without readable glyphs (e.g. F1...F19) are transformed to
                to unicode characters (NSF1FunctionKey...NSF19FunctionKey) suitable for setting key equivalents
                of Cocoa controls or to plain strings (@"F1"...@"F19") suitable for drawing, logging and accessibility.

    @discussion This method is the designated initializer for SRKeyCodeTransformer.
 */
- (instancetype)initWithASCIICapableKeyboardInputSource:(BOOL)aUsesASCII plainStrings:(BOOL)aUsesPlainStrings;

/*!
    Determines whether transformer uses ASCII capable keyboard input source.
 */
@property (readonly) BOOL usesASCIICapableKeyboardInputSource;

/*!
    Determines whether key codes without readable glyphs are transformed to unicode characters
    suitable for setting keqEquivalents or to plain strings suitable for drawing, logging and accessibility.
 */
@property (readonly) BOOL usesPlainStrings;

/*!
    Returns the shared transformer.
 */
+ (instancetype)sharedTransformer;

/*!
    Returns the shared transformer configured to use only ASCII capable keyboard input source.
 */
+ (instancetype)sharedASCIITransformer;

/*!
    Returns the shared transformer configured to transform key codes to plain strings.
 */
+ (SRKeyCodeTransformer *)sharedPlainTransformer;

/*!
    Returns the shared transformer configured to use only ASCII capable keyboard input source
            and to transform key codes to plain strings.
 */
+ (SRKeyCodeTransformer *)sharedPlainASCIITransformer;


/*!
    Returns mapping from special key codes to unicode characters.
 */
+ (NSDictionary *)specialKeyCodesToUnicodeCharactersMapping;

/*!
    Returns mapping from special key codes to plain strings.
 */
+ (NSDictionary *)specialKeyCodesToPlainStringsMapping;

/*!
    Determines whether key code is special.

    @param  aKeyCode Key code to be checked.
 */
- (BOOL)isKeyCodeSpecial:(unsigned short)aKeyCode;

/*!
    Transforms given special key code into unicode character by taking into account modifier flags.
 
    @discussion E.g. the key code 0x30 is transformed to ⇥. But if shift is pressed, it is transformed to ⇤.
 
    @result     Unicode character or plain string. nil if not a special key code.
*/
- (NSString *)transformedSpecialKeyCode:(NSNumber *)aKeyCode withExplicitModifierFlags:(NSNumber *)aModifierFlags;

/*!
    Shorcut to [self transformedValue:aValue withImplicitModifierFlags:aModifierFlags explicitModifierFlags:0]
 */
- (NSString *)transformedValue:(NSNumber *)aValue withModifierFlags:(NSNumber *)aModifierFlags;

/*!
    Transfroms given key code into unicode character by taking into account modifier flags.
 
    @param  aValue An instance of NSNumber (unsigned short) that represents key code.
 
    @param  anImplicitModifierFlags An instance of NSNumber (NSEventModifierFlags) that represents implicit modifier flags like opt in å.
 
    @param  anExplicitModifierFlags An instance of NSNumber (NSEventModifierFlags) that represents explicit modifier flags like shift in shift-⇤.
 */
- (NSString *)transformedValue:(NSNumber *)aValue withImplicitModifierFlags:(NSNumber *)anImplicitModifierFlags explicitModifierFlags:(NSNumber *)anExplicitModifierFlags;

@end


/*!
    These constants represents drawable unicode characters for key codes that do not have
    appropriate constants in Carbon and Cocoa.
 */
typedef NS_ENUM(unichar, SRKeyCodeGlyph)
{
    SRKeyCodeGlyphTabRight = 0x21E5, // ⇥
    SRKeyCodeGlyphTabLeft = 0x21E4, // ⇤
    SRKeyCodeGlyphReturn = 0x2305, // ⌅
    SRKeyCodeGlyphReturnR2L = 0x21A9, // ↩
    SRKeyCodeGlyphDeleteLeft = 0x232B, // ⌫
    SRKeyCodeGlyphDeleteRight = 0x2326, // ⌦
    SRKeyCodeGlyphPadClear = 0x2327, // ⌧
    SRKeyCodeGlyphLeftArrow = 0x2190, // ←
    SRKeyCodeGlyphRightArrow = 0x2192, // →
    SRKeyCodeGlyphUpArrow = 0x2191, // ↑
    SRKeyCodeGlyphDownArrow = 0x2193, // ↓
    SRKeyCodeGlyphPageDown = 0x21DF, // ⇟
    SRKeyCodeGlyphPageUp = 0x21DE, // ⇞
    SRKeyCodeGlyphNorthwestArrow = 0x2196, // ↖
    SRKeyCodeGlyphSoutheastArrow = 0x2198, // ↘
    SRKeyCodeGlyphEscape = 0x238B, // ⎋
    SRKeyCodeGlyphSpace = 0x0020, // ' '
};
