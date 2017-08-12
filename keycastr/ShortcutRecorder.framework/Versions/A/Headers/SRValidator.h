//
//  SRValidator.h
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
//      Andy Kim
//      Silvio Rizzi
//      Ilya Kulakov

#import <Cocoa/Cocoa.h>


@protocol SRValidatorDelegate;

/*!
    Implements logic to check whether shortcut is taken by other parts of the application and system.
 */
@interface SRValidator : NSObject

@property (assign) NSObject<SRValidatorDelegate> *delegate;

- (instancetype)initWithDelegate:(NSObject<SRValidatorDelegate> *)aDelegate;

/*!
    Determines whether shortcut is taken.

    @discussion Key is checked in the following order:
                1. If delegate implements shortcutValidator:isKeyCode:andFlagsTaken:reason:
                2. If delegate allows system-wide shortcuts are checked
                3. If delegate allows application menu it checked

    @see        SRValidatorDelegate
 */
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSEventModifierFlags)aFlags error:(NSError **)outError;

/*!
    Determines whether shortcut is taken in delegate.

    @discussion If delegate does not implement appropriate method, returns immediately.
 */
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagTakenInDelegate:(NSEventModifierFlags)aFlags error:(NSError **)outError;

/*!
    Determines whether shortcut is taken by system-wide shortcuts.

    @discussion Does not check whether delegate allows or disallows checking in system shortcuts.
 */
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlagsTakenInSystemShortcuts:(NSEventModifierFlags)aFlags error:(NSError **)outError;

/*!
    Determines whether shortcut is taken by application menu item.

    @discussion Does not check whether delegate allows or disallows checking in application menu.
 */
- (BOOL)isKeyCode:(unsigned short)aKeyCode andFlags:(NSEventModifierFlags)aFlags takenInMenu:(NSMenu *)aMenu error:(NSError **)outError;

@end


@protocol SRValidatorDelegate

@optional

/*!
    Asks the delegate if aKeyCode and aFlags are valid.

    @param      aValidator The validator that validates key code and flags.

    @param      aKeyCode Key code to validate.

    @param      aFlags Flags to validate.

    @param      outReason If delegate decides that shortcut is invalid, it may pass here an error message.

    @result     YES if shortcut is valid. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidator:(SRValidator *)aValidator isKeyCode:(unsigned short)aKeyCode andFlagsTaken:(NSEventModifierFlags)aFlags reason:(NSString **)outReason;

/*!
    Asks the delegate whether validator should check key equivalents of app's menu items.

    @param      aValidator The validator that going to check app's menu items.

    @result     YES if validator should check key equivalents of app's menu items. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidatorShouldCheckMenu:(SRValidator *)aValidator;

/*!
    Asks the delegate whether it should check system shortcuts.

    @param      aValidator The validator that going to check system shortcuts.

    @result     YES if validator should check system shortcuts. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, checking proceeds as if this method had returned YES.
 */
- (BOOL)shortcutValidatorShouldCheckSystemShortcuts:(SRValidator *)aValidator;

/*!
    Asks the delegate whether it should use ASCII representation of key code when making error messages.

    @param      aValidator The validator that is about to make an error message.

    @result     YES if validator should use ASCII representation. Otherwise NO.

    @discussion Implementation of this method by the delegate is optional. If it is not present, ASCII representation of key code is used.
 */
- (BOOL)shortcutValidatorShouldUseASCIIStringForKeyCodes:(SRValidator *)aValidator;

@end


@interface NSMenuItem (SRValidator)

/*!
    Returns full path to the menu item. E.g. "Window ➝ Zoom"
 */
- (NSString *)SR_path;

@end
