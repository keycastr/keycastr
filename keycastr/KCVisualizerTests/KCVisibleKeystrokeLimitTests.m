//  Copyright (c) 2026 Andrew Kitchen
//
//  All rights reserved.

#import <XCTest/XCTest.h>
#import "KCKeycastrEvent.h"
#import "KCMouseEvent.h"
#import <KCVisualizer/KCKeystroke.h>
#import <KCVisualizer/KCVisualizer.h>

@protocol KCVisibleKeystrokeLimitTesting <NSObject>

@property (nonatomic, assign) NSUInteger maximumVisibleKeystrokes;

@end

@protocol KCSvelteVisualizerViewTesting <NSObject>

- (CGFloat)fontSizeForDisplayedString:(NSString *)displayedString withinWidth:(CGFloat)width;

@end


@interface KCStubKeycastrEvent : KCKeycastrEvent

@property (nonatomic, copy) NSString *displayString;

@end


@interface KCVisibleKeystrokeLimitTests : XCTestCase
@end


@implementation KCVisibleKeystrokeLimitTests

- (void)setUp
{
    [super setUp];
    [KCVisualizer loadPluginsFromDirectory:[[NSBundle bundleForClass:self.class] builtInPlugInsPath]];
}

- (void)tearDown
{
    for (NSString *key in @[@"default.maximumVisibleKeystrokes",
                            @"svelte.maximumVisibleKeystrokes",
                            @"default.commandKeysOnly",
                            @"default.allModifiedKeys",
                            @"default.allKeys"]) {
        [NSUserDefaults.standardUserDefaults removeObjectForKey:key];
    }
    [KCVisualizer unloadPlugins];
    [super tearDown];
}

- (void)test_SvelteVisualizer_defaultsToSixVisibleKeystrokes
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];

    // Act
    NSNumber *maximumVisibleKeystrokes = (NSNumber *)[[visualizer.class visualizerDefaults] objectForKey:@"svelte.maximumVisibleKeystrokes"];

    // Assert
    XCTAssertEqualObjects(maximumVisibleKeystrokes, @6);
}

- (void)test_SvelteVisualizer_limitsEventsInsteadOfCharacters
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 2;
    NSArray<KCStubKeycastrEvent *> *events = [self eventsWithDisplayStrings:@[@"A", @"⌘B", @"⊞1"]];

    // Act
    for (KCStubKeycastrEvent *event in events) {
        [visualizer noteKeyEvent:(id)event];
    }

    // Assert
    id visualizerView = [(NSObject *)visualizer valueForKey:@"visualizerView"];
    XCTAssertEqualObjects([visualizerView valueForKey:@"displayedString"], @"⌘B⊞1");
}

- (void)test_SvelteVisualizer_trimsVisibleKeystrokesWhenLimitDecreases
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 0;
    NSArray<KCStubKeycastrEvent *> *events = [self eventsWithDisplayStrings:@[@"A", @"B", @"C"]];
    for (KCStubKeycastrEvent *event in events) {
        [visualizer noteKeyEvent:(id)event];
    }

    // Act
    visualizerWithLimit.maximumVisibleKeystrokes = 1;

    // Assert
    id visualizerView = [(NSObject *)visualizer valueForKey:@"visualizerView"];
    XCTAssertEqualObjects([visualizerView valueForKey:@"displayedString"], @"C");
}

- (void)test_SvelteVisualizer_exposesMaximumVisibleKeystrokesPreference
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];

    // Act
    NSControl *preferenceControl = [self controlBoundToKeyPath:@"values.svelte.maximumVisibleKeystrokes"
                                                       inView:visualizer.preferencesView];

    // Assert
    XCTAssertNotNil(preferenceControl);
}

- (void)test_SvelteVisualizer_doesNotCountMouseEventsAsKeystrokes
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 2;
    for (KCStubKeycastrEvent *event in [self eventsWithDisplayStrings:@[@"A", @"B"]]) {
        [visualizer noteKeyEvent:(id)event];
    }

    // Act
    [visualizer noteMouseEvent:[self mouseDownEvent]];

    // Assert
    id visualizerView = [(NSObject *)visualizer valueForKey:@"visualizerView"];
    XCTAssertEqualObjects([visualizerView valueForKey:@"displayedString"], @"AB🖱️");
}

- (void)test_SvelteVisualizer_stopsShrinkingFontAtOnePoint
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Svelte"];
    id<KCSvelteVisualizerViewTesting> visualizerView = [(NSObject *)visualizer valueForKey:@"visualizerView"];
    NSString *longDisplayString = [@"M" stringByPaddingToLength:500 withString:@"M" startingAtIndex:0];

    // Act
    CGFloat fontSize = [visualizerView fontSizeForDisplayedString:longDisplayString withinWidth:190];

    // Assert
    XCTAssertEqual(fontSize, 1);
}

- (void)test_DefaultVisualizer_defaultsToUnlimitedVisibleKeystrokes
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Default"];

    // Act
    NSNumber *maximumVisibleKeystrokes = (NSNumber *)[[visualizer.class visualizerDefaults] objectForKey:@"default.maximumVisibleKeystrokes"];

    // Assert
    XCTAssertEqualObjects(maximumVisibleKeystrokes, @0);
}

- (void)test_DefaultVisualizer_limitsKeystrokesAcrossVisibleRows
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Default"];
    [(NSObject *)visualizer setValue:@2 forKey:@"displayMode"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 2;
    NSArray<KCKeystroke *> *keystrokes = @[
        [self keystrokeWithCharacters:@"a" modifierFlags:0 keyCode:0],
        [self keystrokeWithCharacters:@"b" modifierFlags:NSEventModifierFlagCommand keyCode:11],
        [self keystrokeWithCharacters:@"c" modifierFlags:0 keyCode:8],
    ];

    // Act
    for (KCKeystroke *keystroke in keystrokes) {
        [visualizer noteKeyEvent:keystroke];
    }

    // Assert
    XCTAssertEqualObjects([self visibleStringsForDefaultVisualizer:visualizer], (@[@"⌘B", @"c"]));
}

- (void)test_DefaultVisualizer_trimsVisibleKeystrokesWhenLimitDecreases
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Default"];
    [(NSObject *)visualizer setValue:@2 forKey:@"displayMode"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 0;
    NSArray<KCKeystroke *> *keystrokes = @[
        [self keystrokeWithCharacters:@"a" modifierFlags:0 keyCode:0],
        [self keystrokeWithCharacters:@"b" modifierFlags:0 keyCode:11],
        [self keystrokeWithCharacters:@"c" modifierFlags:0 keyCode:8],
    ];
    for (KCKeystroke *keystroke in keystrokes) {
        [visualizer noteKeyEvent:keystroke];
    }

    // Act
    visualizerWithLimit.maximumVisibleKeystrokes = 1;

    // Assert
    XCTAssertEqualObjects([self visibleStringsForDefaultVisualizer:visualizer], (@[@"c"]));
}

- (void)test_DefaultVisualizer_exposesMaximumVisibleKeystrokesPreference
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Default"];

    // Act
    NSControl *preferenceControl = [self controlBoundToKeyPath:@"values.default.maximumVisibleKeystrokes"
                                                       inView:visualizer.preferencesView];

    // Assert
    XCTAssertNotNil(preferenceControl);
}

- (void)test_DefaultVisualizer_closesGapWhenRemovingMiddleRow
{
    // Arrange
    id<KCVisualizer> visualizer = [KCVisualizer visualizerWithName:@"Default"];
    [(NSObject *)visualizer setValue:@2 forKey:@"displayMode"];
    id<KCVisibleKeystrokeLimitTesting> visualizerWithLimit = (id)visualizer;
    visualizerWithLimit.maximumVisibleKeystrokes = 0;
    [visualizer noteMouseEvent:[self mouseDownEvent]];
    NSWindow *visualizerWindow = [(NSObject *)visualizer valueForKey:@"visualizerWindow"];
    [visualizerWindow performSelector:@selector(abandonCurrentBezelView)];
    [visualizer noteKeyEvent:[self keystrokeWithCharacters:@"a" modifierFlags:0 keyCode:0]];
    [visualizer noteKeyEvent:[self keystrokeWithCharacters:@"b" modifierFlags:NSEventModifierFlagCommand keyCode:11]];
    XCTAssertEqual(visualizerWindow.contentView.subviews.count, 3);

    // Act
    visualizerWithLimit.maximumVisibleKeystrokes = 1;

    // Assert
    XCTAssertEqual(visualizerWindow.contentView.subviews.count, 2);
    for (NSView *bezelView in visualizerWindow.contentView.subviews) {
        XCTAssertGreaterThanOrEqual(NSMinY(bezelView.frame), 0);
        XCTAssertLessThanOrEqual(NSMaxY(bezelView.frame), NSHeight(visualizerWindow.contentView.bounds));
    }
}

- (void)test_VisualizersDoNotPersistRegisteredDefaultsDuringInitialization
{
    // Arrange
    NSUserDefaults *userDefaults = NSUserDefaults.standardUserDefaults;
    [userDefaults removeObjectForKey:@"svelte.maximumVisibleKeystrokes"];
    [userDefaults removeObjectForKey:@"default.maximumVisibleKeystrokes"];

    // Act
    [KCVisualizer visualizerWithName:@"Svelte"];
    [KCVisualizer visualizerWithName:@"Default"];

    // Assert
    NSDictionary *persistentDefaults = [userDefaults persistentDomainForName:NSBundle.mainBundle.bundleIdentifier];
    XCTAssertNil([persistentDefaults objectForKey:@"svelte.maximumVisibleKeystrokes"]);
    XCTAssertNil([persistentDefaults objectForKey:@"default.maximumVisibleKeystrokes"]);
}

- (NSArray<KCStubKeycastrEvent *> *)eventsWithDisplayStrings:(NSArray<NSString *> *)displayStrings
{
    NSMutableArray<KCStubKeycastrEvent *> *events = [NSMutableArray array];
    for (NSString *displayString in displayStrings) {
        KCStubKeycastrEvent *event = [[KCStubKeycastrEvent alloc] initWithNSEvent:[self keyEventWithCharacters:displayString modifierFlags:0 keyCode:0]];
        event.displayString = displayString;
        [events addObject:event];
    }
    return events;
}

- (KCKeystroke *)keystrokeWithCharacters:(NSString *)characters
                            modifierFlags:(NSEventModifierFlags)modifierFlags
                                  keyCode:(unsigned short)keyCode
{
    NSEvent *event = [self keyEventWithCharacters:characters modifierFlags:modifierFlags keyCode:keyCode];
    return [[KCKeystroke alloc] initWithNSEvent:event];
}

- (NSEvent *)keyEventWithCharacters:(NSString *)characters
                      modifierFlags:(NSEventModifierFlags)modifierFlags
                            keyCode:(unsigned short)keyCode
{
    return [NSEvent keyEventWithType:NSEventTypeKeyDown
                            location:NSZeroPoint
                       modifierFlags:modifierFlags
                           timestamp:NSDate.timeIntervalSinceReferenceDate
                        windowNumber:0
                             context:nil
                          characters:characters
         charactersIgnoringModifiers:characters
                           isARepeat:NO
                             keyCode:keyCode];
}

- (KCMouseEvent *)mouseDownEvent
{
    NSEvent *event = [NSEvent mouseEventWithType:NSEventTypeLeftMouseDown
                                        location:NSZeroPoint
                                   modifierFlags:0
                                       timestamp:NSDate.timeIntervalSinceReferenceDate
                                    windowNumber:0
                                         context:nil
                                     eventNumber:0
                                      clickCount:1
                                        pressure:1];
    return [[KCMouseEvent alloc] initWithNSEvent:event];
}

- (NSArray<NSString *> *)visibleStringsForDefaultVisualizer:(id<KCVisualizer>)visualizer
{
    NSWindow *visualizerWindow = [(NSObject *)visualizer valueForKey:@"visualizerWindow"];
    NSMutableArray<NSString *> *visibleStrings = [NSMutableArray array];
    for (NSView *bezelView in visualizerWindow.contentView.subviews) {
        [visibleStrings addObjectsFromArray:[bezelView valueForKey:@"displayedKeystrokes"]];
    }
    return visibleStrings;
}

- (NSControl *)controlBoundToKeyPath:(NSString *)keyPath inView:(NSView *)view
{
    if ([view isKindOfClass:NSControl.class]) {
        NSDictionary *bindingInfo = [(NSControl *)view infoForBinding:NSValueBinding];
        if ([[bindingInfo objectForKey:NSObservedKeyPathKey] isEqualToString:keyPath]) {
            return (NSControl *)view;
        }
    }

    for (NSView *subview in view.subviews) {
        NSControl *control = [self controlBoundToKeyPath:keyPath inView:subview];
        if (control) {
            return control;
        }
    }
    return nil;
}

@end


@implementation KCStubKeycastrEvent

- (BOOL)isCommand
{
    return NO;
}

- (NSString *)convertToString
{
    return self.displayString;
}

@end
