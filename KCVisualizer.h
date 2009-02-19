//
//  KCVisualizer.h
//  KeyCastr
//
//  Created by Stephen Deken on 1/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KCKeystroke.h"

@protocol KCVisualizer

-(NSView*) preferencesView;
-(NSString*) visualizerName;

-(void) showVisualizerWindow:(id)sender;
-(void) hideVisualizerWindow:(id)sender;

-(void) noteKeyEvent:(KCKeystroke*)keystroke;

@end


@protocol KCVisualizerFactory

-(NSString*) visualizerNibName;
-(Class) visualizerClass;
-(id<KCVisualizer>) constructVisualizer;
-(NSString*) visualizerName;

@end


@interface KCVisualizer : NSObject <KCVisualizer>
{
	IBOutlet NSView* preferencesView;
}

+(void) registerVisualizerFactory:(id<KCVisualizerFactory>)factory withName:(NSString*)name;
+(id<KCVisualizer>) visualizerWithName:(NSString*)visualizerName;
+(NSArray*) availableVisualizerFactories;

-(NSView*) preferencesView;
-(NSString*) visualizerName;

-(void) showVisualizerWindow:(id)sender;
-(void) hideVisualizerWindow:(id)sender;
-(void) noteKeyEvent:(KCKeystroke*)keystroke;

@end


@interface KCVisualizerFactory : NSObject <KCVisualizerFactory>
{
}

-(id<KCVisualizer>) constructVisualizer;

@end

