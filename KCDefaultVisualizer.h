//
//  KCDefaultVisualizer.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/29/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KCVisualizer.h"

@interface KCDefaultVisualizerFactory : KCVisualizerFactory <KCVisualizerFactory>
{
}

-(NSString*) visualizerNibName;
-(Class) visualizerClass;
-(NSString*) visualizerName;

@end

@interface KCDefaultVisualizerBezelView : NSView
{
	double _maxWidth;
	NSColor* _foregroundColor;
	NSColor* _backgroundColor;
	double _fontSize;
	NSString* _contentText;
	BOOL _isCommand;
	float _opacity;

	NSTextStorage* _textStorage;
	NSLayoutManager* _layoutManager;
	NSTextContainer* _textContainer;
}

-(id) initWithMaxWidth:(double)maxWidth text:(NSString*)string isCommand:(BOOL)isCommand fontSize:(double)size fontColor:(NSColor*)fontColor backgroundColor:(NSColor*)color;
-(NSDictionary*) attributes;
-(void) maybeResize;
-(NSShadow*) shadow;
-(BOOL) isCommand;
-(void) setAlphaValue:(float)opacity;
-(void) appendString:(NSString*)t;

@end

@class KCDefaultVisualizerWindow;

@interface KCBezelAnimation : NSAnimation
{
	KCDefaultVisualizerBezelView* _bezelView;
	NSWindow* _window;
}

-(KCBezelAnimation*) initWithBezelView:(KCDefaultVisualizerBezelView*)bezelView;
-(KCBezelAnimation*) initWithBezelView:(KCDefaultVisualizerBezelView*)bezelView window:(KCDefaultVisualizerWindow*)window;

@end

@interface KCDefaultVisualizerWindow : NSWindow
{
	NSMutableArray* _bezelViews;
	KCDefaultVisualizerBezelView* _mostRecentBezelView;
	NSMutableArray* _runningAnimations;
	BOOL _dragging;
}

-(void) addKeystroke:(KCKeystroke*)keystroke;
-(void) abandonCurrentView;
-(void) addRunningAnimation:(KCBezelAnimation*)animation;

@end

@interface KCDefaultVisualizer : KCVisualizer <KCVisualizer>
{
	KCDefaultVisualizerWindow* visualizerWindow;
}

-(NSString*) visualizerName;

@end

