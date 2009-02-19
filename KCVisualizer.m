//
//  KCVisualizer.m
//  KeyCastr
//
//  Created by Stephen Deken on 1/28/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "KCVisualizer.h"

@interface KCVisualizer (Private)

+(NSMutableDictionary*) _registry;

@end

@implementation KCVisualizer

+(NSMutableDictionary*) _registry
{
	static NSMutableDictionary* registry = nil;
	if (registry == nil)
		registry = [[NSMutableDictionary alloc] initWithCapacity:2];
	return registry;
}

+(void) registerVisualizerFactory:(id<KCVisualizerFactory>)factory withName:(NSString*)name
{
	[[KCVisualizer _registry] setObject:factory forKey:name];
}

+(id<KCVisualizer>) visualizerWithName:(NSString*)visualizerName
{
	return [[[KCVisualizer _registry] objectForKey:visualizerName] constructVisualizer];
}

+(NSArray*) availableVisualizerFactories
{
	return [[KCVisualizer _registry] allValues];
}

-(NSView*) preferencesView
{
	return preferencesView;
}

-(NSString*) visualizerName
{
	@throw [NSException exceptionWithName:@"KCNotImplementedException" reason:@"The method visualizerName must be implemented in a subclass." userInfo:nil];
	return nil;
}

-(void) showVisualizerWindow:(id)sender
{
}

-(void) hideVisualizerWindow:(id)sender
{
}

-(void) noteKeyEvent:(KCKeystroke*)keystroke
{
}

@end

@implementation KCVisualizerFactory

-(NSString*) visualizerNibName
{
	@throw [NSException exceptionWithName:@"KCNotImplementedException" reason:@"The method visualizerNibName must be implemented in a subclass." userInfo:nil];
	return nil;
}

-(Class) visualizerClass
{
	@throw [NSException exceptionWithName:@"KCNotImplementedException" reason:@"The method visualizerClass must be implemented in a subclass." userInfo:nil];
	return nil;
}

-(id<KCVisualizer>) constructVisualizer
{
	Class c = [self visualizerClass];
	id<KCVisualizer> v = [[[c alloc] init] retain];
	NSNib* nib = [[NSNib alloc] initWithNibNamed:[self visualizerNibName] bundle:[NSBundle bundleForClass:[self class]]];
	if (![nib instantiateNibWithOwner:v topLevelObjects:nil])
		return nil;
	return v;
}

-(NSString*) visualizerName
{
	@throw [NSException exceptionWithName:@"KCNotImplementedException" reason:@"The method visualizerName must be implemented in a subclass." userInfo:nil];
	return nil;
}

@end