#import <XCTest/XCTest.h>
#import <KCVisualizer/KCKeystroke.h>
#import <KCVisualizer/KCEventTransformer.h>

@interface KCEventTransformerTests : XCTestCase
@property (nonatomic, strong) KCKeystroke *keystroke;
@property (nonatomic, strong) NSUserDefaults *userDefaults;
@property (nonatomic, strong) KCEventTransformer *eventTransformer;
@end

@implementation KCEventTransformerTests

@synthesize keystroke = keystroke, userDefaults = userDefaults, eventTransformer = eventTransformer;

- (KCKeystroke *)keystrokeWithKeyCode:(unsigned short)keyCode modifiers:(NSEventModifierFlags)modifiers characters:(NSString *)characters charactersIgnoringModifiers:(NSString *)charactersIgnoringModifiers {
    NSEvent *fakeEvent = [NSEvent keyEventWithType:NSEventTypeKeyDown
                                          location:NSZeroPoint
                                     modifierFlags:modifiers
                                         timestamp:NSDate.timeIntervalSinceReferenceDate
                                      windowNumber:0
                                           context:nil
                                        characters:characters
                       charactersIgnoringModifiers:charactersIgnoringModifiers
                                         isARepeat:NO
                                           keyCode:keyCode];
    return [[KCKeystroke alloc] initWithNSEvent:fakeEvent];
}

- (void)setUp {
    [super setUp];
    
    // Use the current user's layout
    TISInputSourceRef currentLayout = TISCopyCurrentKeyboardLayoutInputSource();
    
    userDefaults = [[NSUserDefaults alloc] initWithSuiteName:NSStringFromClass([self class])];
    eventTransformer = [[KCEventTransformer alloc] initWithKeyboardLayout:currentLayout userDefaults:userDefaults];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCommandModifierUppercasesCharacters {
    // Create a keystroke with Command modifier
    keystroke = [self keystrokeWithKeyCode:8 modifiers:NSEventModifierFlagCommand characters:@"c" charactersIgnoringModifiers:@"c"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is uppercase with the command symbol
    XCTAssertTrue([result containsString:@"⌘"], @"Result should contain command symbol");
    XCTAssertTrue([result containsString:@"C"], @"Result should contain uppercase C");
    XCTAssertFalse([result containsString:@"c"], @"Result should not contain lowercase c");
}

- (void)testOptionModifierUppercasesCharacters {
    // Create a keystroke with Option modifier
    keystroke = [self keystrokeWithKeyCode:8 modifiers:NSEventModifierFlagOption characters:@"c" charactersIgnoringModifiers:@"c"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is uppercase with the option symbol
    XCTAssertTrue([result containsString:@"⌥"], @"Result should contain option symbol");
    XCTAssertTrue([result containsString:@"C"], @"Result should contain uppercase C");
    XCTAssertFalse([result containsString:@"c"], @"Result should not contain lowercase c");
}

- (void)testControlModifierUppercasesCharacters {
    // Create a keystroke with Control modifier
    keystroke = [self keystrokeWithKeyCode:8 modifiers:NSEventModifierFlagControl characters:@"c" charactersIgnoringModifiers:@"c"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is uppercase with the control symbol
    XCTAssertTrue([result containsString:@"⌃"], @"Result should contain control symbol");
    XCTAssertTrue([result containsString:@"C"], @"Result should contain uppercase C");
    XCTAssertFalse([result containsString:@"c"], @"Result should not contain lowercase c");
}

- (void)testShiftModifierUppercasesCharacters {
    // Create a keystroke with Shift modifier
    keystroke = [self keystrokeWithKeyCode:8 modifiers:NSEventModifierFlagShift characters:@"C" charactersIgnoringModifiers:@"C"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is uppercase with the shift symbol
    XCTAssertTrue([result containsString:@"⇧"], @"Result should contain shift symbol");
    XCTAssertTrue([result containsString:@"C"], @"Result should contain uppercase C");
    XCTAssertFalse([result containsString:@"c"], @"Result should not contain lowercase c");
}

- (void)testMultipleModifiersUppercaseCharacters {
    // Create a keystroke with multiple modifiers
    keystroke = [self keystrokeWithKeyCode:8 modifiers:(NSEventModifierFlagOption | NSEventModifierFlagCommand) characters:@"c" charactersIgnoringModifiers:@"c"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is uppercase with both symbols
    XCTAssertTrue([result containsString:@"⌥"], @"Result should contain option symbol");
    XCTAssertTrue([result containsString:@"⌘"], @"Result should contain command symbol");
    XCTAssertTrue([result containsString:@"C"], @"Result should contain uppercase C");
    XCTAssertFalse([result containsString:@"c"], @"Result should not contain lowercase c");
}

- (void)testNoModifierShowsLowercaseCharacter {
    // Create a keystroke with no modifiers
    keystroke = [self keystrokeWithKeyCode:8 modifiers:0 characters:@"c" charactersIgnoringModifiers:@"c"];
    
    // Get the transformed value
    NSString *result = [eventTransformer transformedValue:keystroke];
    
    // Verify that the character is lowercase with no modifier symbols
    XCTAssertEqualObjects(result, @"c", @"Result should be exactly lowercase c");
}

@end
